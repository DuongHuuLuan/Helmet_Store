import hashlib
import hmac
import urllib.parse
from collections import OrderedDict
from datetime import datetime
from decimal import Decimal
from typing import Optional

from fastapi import HTTPException

from app.core.config import settings
from app.domain.repositories.order_repository import OrderRepository
from app.domain.repositories.vnpay_transaction_repository import VnPayTransactionRepository
from app.infrastructure.database.models.order import Order, OrderStatus, PaymentStatus


class VnpayService:
    def __init__(
        self,
        order_repo: OrderRepository,
        vnpay_txn_repo: VnPayTransactionRepository,
    ):
        self._order_repo = order_repo
        self._vnpay_txn_repo = vnpay_txn_repo

    def create_payment_url(
        self,
        order_id: int,
        ip_address: str,
        bank_code: Optional[str] = None,
        locale: Optional[str] = "vn",
        return_url: Optional[str] = None,
    ) -> str:
        order = self._order_repo.get_by_id_with_details(order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")

        self.sync_order_payment_status(order, commit=True)

        if order.status != OrderStatus.PENDING:
            raise HTTPException(status_code=400, detail="Chỉ có thể thanh toán cho đơn hàng chờ duyệt")

        if order.payment_status == PaymentStatus.PAID:
            raise HTTPException(status_code=400, detail="Đơn hàng này đã được thanh toán")

        if not settings.VNPAY_TMN_CODE or not settings.VNPAY_HASH_SECRET:
            raise HTTPException(status_code=400, detail="Cấu hình VNPAY bị thiếu")

        amount = VnpayService._get_order_total(order)
        if amount <= 0:
            raise HTTPException(status_code=400, detail="Số tiền đặt hàng không hợp lệ")

        vnp_return_url = return_url or settings.VNPAY_RETURN_URL
        if not vnp_return_url:
            raise HTTPException(status_code=400, detail="Thiếu VNPAY_RETURN_URL")

        params = {
            "vnp_Version": settings.VNPAY_VERSION,
            "vnp_Command": "pay",
            "vnp_TmnCode": settings.VNPAY_TMN_CODE,
            "vnp_Amount": int(amount * 100),
            "vnp_CurrCode": "VND",
            "vnp_TxnRef": str(order.id),
            "vnp_OrderInfo": f"Thanh toán đơn hàng {order.id}",
            "vnp_OrderType": "other",
            "vnp_Locale": locale or "vn",
            "vnp_ReturnUrl": vnp_return_url,
            "vnp_IpAddr": ip_address,
            "vnp_CreateDate": datetime.now().strftime("%Y%m%d%H%M%S"),
        }
        if bank_code:
            params["vnp_BankCode"] = bank_code

        query = VnpayService._build_query(params)
        secure_hash = VnpayService._hash_data(query)
        return f"{settings.VNPAY_URL}?{query}&vnp_SecureHash={secure_hash}"

    @staticmethod
    def verify_signature(params: dict) -> bool:
        if not params:
            return False

        params = dict(params)
        vnp_secure_hash = params.pop("vnp_SecureHash", None)
        params.pop("vnp_SecureHashType", None)

        query = VnpayService._build_query(params)
        expected = VnpayService._hash_data(query)
        return (vnp_secure_hash or "").lower() == expected.lower()

    def handle_ipn(self, params: dict) -> dict:
        if not VnpayService.verify_signature(params):
            return {"RspCode": "97", "Message": "Chữ ký không hợp lệ"}

        try:
            try:
                order_id = int(params.get("vnp_TxnRef") or 0)
            except ValueError:
                return {"RspCode": "01", "Message": "Định dạng mã đơn hàng không hợp lệ"}

            order = self._order_repo.get_by_id_with_details(order_id)
            if not order:
                return {"RspCode": "01", "Message": "Không tìm thấy đơn hàng"}

            amount = Decimal(params.get("vnp_Amount") or 0) / Decimal("100")
            expected_amount = VnpayService._get_order_total(order)
            if amount != expected_amount:
                return {"RspCode": "04", "Message": "Số tiền không hợp lệ"}

            response_code = params.get("vnp_ResponseCode")
            transaction_status = params.get("vnp_TransactionStatus")
            is_success = response_code == "00" and transaction_status == "00"

            if is_success and order.payment_status == PaymentStatus.PAID:
                return {
                    "RspCode": "00",
                    "Message": "Đơn hàng đã ghi nhận thanh toán trước đó",
                }

            self.record_transaction(params)
            current_payment_status = self.sync_order_payment_status(
                order,
                commit=True,
            )

            if is_success:
                return {
                    "RspCode": "00",
                    "Message": (
                        "Đã ghi nhận thanh toán, đơn tiếp tục chờ duyệt"
                        if order.status == OrderStatus.PENDING
                        else "Đã ghi nhận thanh toán cho đơn hàng"
                    ),
                }

            if order.status != OrderStatus.PENDING:
                return {
                    "RspCode": "02",
                    "Message": "Đơn hàng không còn ở trạng thái chờ duyệt",
                }

            return {
                "RspCode": "00",
                "Message": (
                    "Ghi nhận trạng thái thanh toán thất bại"
                    if current_payment_status == PaymentStatus.UNPAID
                    else "Đơn hàng đã có giao dịch thanh toán thành công trước đó"
                ),
            }
        except Exception as exc:
            return {"RspCode": "99", "Message": f"Lỗi hệ thống: {str(exc)}"}

    @staticmethod
    def _build_query(params: dict) -> str:
        sorted_params = OrderedDict(sorted(params.items()))
        parts = []
        for key, value in sorted_params.items():
            if value is not None and value != "":
                encoded_key = urllib.parse.quote_plus(str(key))
                encoded_value = urllib.parse.quote_plus(str(value))
                parts.append(f"{encoded_key}={encoded_value}")
        return "&".join(parts)

    @staticmethod
    def _hash_data(query: str) -> str:
        secret = settings.VNPAY_HASH_SECRET or ""
        return hmac.new(
            secret.encode("utf-8"),
            query.encode("utf-8"),
            hashlib.sha512,
        ).hexdigest()

    @staticmethod
    def _get_order_total(order) -> Decimal:
        total = Decimal("0")
        for detail in getattr(order, "order_details", []) or []:
            price = getattr(detail, "price", 0) or 0
            qty = getattr(detail, "quantity", 0) or 0
            total += Decimal(str(price)) * Decimal(str(qty))
        return total

    def sync_order_payment_status(self, order, commit: bool = True):
        current_status = getattr(order, "payment_status", None)
        if current_status == PaymentStatus.PAID:
            return order.payment_status if hasattr(order, "payment_status") else current_status

        shipped_amount = Decimal("0")
        total_amount = Decimal("0")
        for detail in getattr(order, "order_details", []) or []:
            price = getattr(detail, "price", 0) or 0
            qty = getattr(detail, "quantity", 0) or 0
            total_amount += Decimal(str(price)) * Decimal(str(qty))

        for shipment in getattr(order, "ghn_shipments", []) or []:
            cod_amount = getattr(shipment, "cod_amount", 0) or 0
            shipped_amount += Decimal(str(cod_amount))

        new_status = PaymentStatus.PAID if shipped_amount > 0 else PaymentStatus.UNPAID

        if commit and current_status != new_status:
            self._order_repo.update_payment_status(order.id, new_status.value)

        return new_status

    def record_transaction(self, params: dict) -> None:
        self._vnpay_txn_repo.create(
            {
                "order_id": int(params.get("vnp_TxnRef") or 0),
                "txn_ref": params.get("vnp_TxnRef", ""),
                "amount": Decimal(str(params.get("vnp_Amount", 0))) / Decimal("100"),
                "response_code": params.get("vnp_ResponseCode", ""),
                "status": params.get("vnp_TransactionStatus", ""),
                "transaction_no": params.get("vnp_TransactionNo", ""),
                "bank_code": params.get("vnp_BankCode", ""),
                "pay_date": params.get("vnp_PayDate", ""),
                "message": params.get("vnp_Message", ""),
            }
        )
