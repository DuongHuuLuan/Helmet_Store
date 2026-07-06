from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import RedirectResponse
from urllib.parse import urlencode

from app.presentation.api.deps import require_user
from app.core.config import settings
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.vnpay_dto import VnpayCreateRequest, VnpayPaymentUrlOut
from app.infrastructure.external.vnpay.service import VnpayService

router = APIRouter(prefix="/vnpay", tags=["VNPAY"])


def get_vnpay_service():
    from app.shared.dependencies import get_vnpay_service as _get_vnpay_service
    return _get_vnpay_service()


@router.post("/create-payment", response_model=VnpayPaymentUrlOut)
def create_payment_url(
    payload: VnpayCreateRequest,
    request: Request,
    current_user: User = Depends(require_user),
    vnpay_service: VnpayService = Depends(get_vnpay_service),
):
    base_url = str(request.base_url).rstrip("/")
    return_url = settings.VNPAY_RETURN_URL or f"{base_url}/vnpay/return"
    ip_address = request.client.host if request.client else "0.0.0.0"

    payment_url = vnpay_service.create_payment_url(
        order_id=payload.order_id,
        ip_address=ip_address,
        bank_code=payload.bank_code,
        locale=payload.locale,
        return_url=return_url,
    )
    return {"payment_url": payment_url}


@router.get("/return")
def vnpay_return(
    request: Request,
    vnpay_service: VnpayService = Depends(get_vnpay_service),
):
    params = dict(request.query_params)
    
    if not params:
        raise HTTPException(status_code=400, detail="No data received")
    
    is_valid = vnpay_service.verify_signature(params)
    order_id = params.get("vnp_TxnRef", "")
    response_code = params.get("vnp_ResponseCode")
    transaction_status = params.get("vnp_TransactionStatus")
    is_success = response_code == "00" and transaction_status == "00"

    ipn_result = None
    if is_valid:
        ipn_result = vnpay_service.handle_ipn(params)

    app_return_url = settings.APP_RETURN_URL or (
        f"{settings.APP_DEEP_LINK_SCHEME}://payment-result"
    )
    separator = "&" if "?" in app_return_url else "?"
    redirect_query = urlencode(
        {
            "orderId": order_id,
            "status": "success" if (is_valid and is_success) else "failed",
            "valid": "1" if is_valid else "0",
            "paymentStatus": "paid" if (is_valid and is_success) else "unpaid",
            "orderStatus": "pending",
            "reviewStatus": "pending",
            "message": (ipn_result or {}).get("Message", ""),
        }
    )
    redirect_url = f"{app_return_url}{separator}{redirect_query}"
    return RedirectResponse(url=redirect_url, status_code=302)


@router.get("/ipn")
def vnpay_ipn(request: Request):
    params = dict(request.query_params)
    from app.shared.dependencies import get_vnpay_service
    vnpay_service = get_vnpay_service()
    return vnpay_service.handle_ipn(params)
