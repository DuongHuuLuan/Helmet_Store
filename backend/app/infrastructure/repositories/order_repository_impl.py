import math
from datetime import date, datetime
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.domain.repositories.order_repository import OrderRepository
from app.infrastructure.database.models.cart import Cart
from app.infrastructure.database.models.cart_detail import CartDetail
from app.infrastructure.database.models.design import Design
from app.infrastructure.database.models.design_layer import DesignLayer
from app.infrastructure.database.models.discount import Discount, DiscountStatus
from app.infrastructure.database.models.order import Order, OrderDetail, OrderStatus, PaymentStatus, RefundSupportStatus
from app.infrastructure.database.models.product import Product
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.user import User
from app.infrastructure.repositories.warehouse_repository_impl import WarehouseRepositoryImpl
from app.domain.services.snapshot_service import ProductionSnapshotService


class OrderRepositoryImpl(OrderRepository):
    def __init__(self, db: Session):
        self.db = db

    def _base_query(self):
        return self.db.query(Order).options(
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product)
                .joinedload(Product.product_images),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.color),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.size),
            joinedload(Order.order_details).joinedload(OrderDetail.design),
            joinedload(Order.delivery_info),
            joinedload(Order.payment_method),
            joinedload(Order.applied_discounts),
            joinedload(Order.ghn_shipments),
            joinedload(Order.vnpay_transactions),
        )

    def _admin_query(self):
        return self.db.query(Order).options(
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product)
                .joinedload(Product.product_images),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.color),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.size),
            joinedload(Order.order_details).joinedload(OrderDetail.design),
            joinedload(Order.delivery_info),
            joinedload(Order.payment_method),
            joinedload(Order.user),
            joinedload(Order.applied_discounts),
            joinedload(Order.ghn_shipments),
            joinedload(Order.vnpay_transactions),
        )

    def _is_completed_cod_order(self, order: Order) -> bool:
        if getattr(order, "status", None) != OrderStatus.COMPLETED:
            return False
        payment_method = getattr(order, "payment_method", None)
        payment_method_name = str(getattr(payment_method, "name", "") or "").strip().lower()
        return "cod" in payment_method_name

    def sync_payment_statuses(self, orders: list) -> list:
        if not orders:
            return orders
        has_changes = False
        for order in orders:
            transactions = getattr(order, "vnpay_transactions", None) or []
            has_success = any(
                (txn.status or "").strip().lower() == "success"
                for txn in transactions
            )
            next_status = (
                PaymentStatus.PAID
                if has_success or self._is_completed_cod_order(order)
                else PaymentStatus.UNPAID
            )
            if order.payment_status != next_status:
                order.payment_status = next_status
                has_changes = True
        if has_changes:
            self.db.commit()
            for order in orders:
                self.db.refresh(order)
        return orders

    def _get_cart_for_checkout(self, user_id: int):
        return (
            self.db.query(Cart)
            .options(
                joinedload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.product),
                joinedload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.color),
                joinedload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.size),
                joinedload(Cart.cart_details)
                    .joinedload(CartDetail.design)
                    .joinedload(Design.layers)
                    .joinedload(DesignLayer.sticker),
            )
            .filter(Cart.user_id == user_id)
            .first()
        )

    def _resolve_selected_cart_details(self, cart, order_items: Optional[list[dict]]):
        if order_items is None:
            return [(cd, cd.quantity) for cd in cart.cart_details]

        if not order_items:
            raise HTTPException(status_code=400, detail="Danh sách mua không được rỗng")

        by_id = {cd.id: cd for cd in cart.cart_details}
        by_pd: dict[int, list] = {}
        for cd in cart.cart_details:
            by_pd.setdefault(cd.product_detail_id, []).append(cd)

        selected_ids = set()
        selections = []

        for item in order_items:
            quantity = item["quantity"]
            if quantity <= 0:
                raise HTTPException(status_code=400, detail="Số lượng mua phải lớn hơn 0")

            cd = None
            cart_detail_id = item.get("cart_detail_id")
            if cart_detail_id is not None:
                cd = by_id.get(cart_detail_id)
                if cd is None:
                    raise HTTPException(status_code=400, detail="Mục giỏ hàng không tồn tại hoặc không thuộc người dùng hiện tại")
            else:
                pid = item.get("product_detail_id", 0)
                matches = by_pd.get(pid, [])
                if not matches:
                    raise HTTPException(status_code=400, detail="Sản phẩm không có trong giỏ hàng")
                if len(matches) > 1:
                    raise HTTPException(status_code=400, detail="Biến thể sản phẩm này có nhiều mục trong giỏ hàng. Vui lòng gửi cart_detail_id để chọn đúng mục cần đặt.")
                cd = matches[0]

            if cd.id in selected_ids:
                raise HTTPException(status_code=400, detail="Trùng mục giỏ hàng trong danh sách mua")

            if quantity > cd.quantity:
                pname = cd.product_detail.product.name if cd.product_detail and cd.product_detail.product else "Sản phẩm"
                raise HTTPException(status_code=400, detail=f"Số lượng mua vượt quá số lượng trong giỏ hàng: {pname}")

            selected_ids.add(cd.id)
            selections.append((cd, quantity))

        return selections

    def create_order(
        self,
        user_id: int,
        delivery_info_id: int,
        payment_method_id: int,
        discount_ids: Optional[list[int]] = None,
        order_items: Optional[list[dict]] = None,
    ):
        cart = self._get_cart_for_checkout(user_id)
        if not cart or not cart.cart_details:
            raise HTTPException(status_code=400, detail="Giỏ hàng trống")

        selected_items = self._resolve_selected_cart_details(cart, order_items)

        order_details_data = []
        cart_details = []

        for cart_detail, requested_quantity in selected_items:
            product_detail = cart_detail.product_detail
            if not product_detail:
                raise HTTPException(status_code=400, detail=f"Sản phẩm ID {cart_detail.product_detail_id} không còn tồn tại")

            available_qty = WarehouseRepositoryImpl(self.db).get_total_stock_for_detail(product_detail)
            if available_qty < requested_quantity:
                product_name = product_detail.product.name if product_detail.product else f"ID {cart_detail.product_detail_id}"
                raise HTTPException(status_code=400, detail=f"Sản phẩm {product_name} không đủ hàng")

            cart_details.append((cart_detail, product_detail, requested_quantity))
            WarehouseRepositoryImpl(self.db).decrease_stock(
                product_id=product_detail.product_id,
                color_id=product_detail.color_id,
                size_id=product_detail.size_id,
                quantity=requested_quantity,
            )

        category_ids = {
            pd.product.category_id
            for _, pd, _ in cart_details
            if pd.product and pd.product.category_id
        }
        category_discounts = {}
        selected_discounts = []

        if discount_ids is None:
            from app.infrastructure.repositories.discount_repository_impl import DiscountRepositoryImpl
            category_discounts = DiscountRepositoryImpl(self.db).get_grouped_by_category_ids(list(category_ids))
            selected_discounts = list(category_discounts.values())
        else:
            raw_ids = [int(did) for did in discount_ids]
            unique_ids = list(dict.fromkeys(raw_ids))
            if unique_ids:
                now = datetime.now()
                valid = self.db.query(Discount).filter(
                    Discount.id.in_(unique_ids),
                    Discount.status == DiscountStatus.ACTIVE,
                    Discount.start_at <= now,
                    Discount.end_at >= now,
                ).all()

                valid_by_id = {d.id: d for d in valid}
                missing = [did for did in unique_ids if did not in valid_by_id]
                if missing:
                    raise HTTPException(status_code=400, detail="Có mã giảm giá không hợp lệ hoặc đã hết hạn")

                for did in unique_ids:
                    d = valid_by_id[did]
                    if d.category_id not in category_ids:
                        raise HTTPException(status_code=400, detail=f"Mã giảm giá {d.name} không áp dụng cho sản phẩm đã chọn")
                    if d.category_id in category_discounts:
                        raise HTTPException(status_code=400, detail="Chỉ được chọn một mã giảm giá cho mỗi danh mục")
                    category_discounts[d.category_id] = d
                    selected_discounts.append(d)

        for cart_detail, product_detail, requested_quantity in cart_details:
            unit_price = Decimal(str(product_detail.price or 0))
            discount = None
            if product_detail.product:
                discount = category_discounts.get(product_detail.product.category_id)

            discounted_unit_price = unit_price
            if discount:
                percent = Decimal(str(discount.percent))
                multiplier = (Decimal("100") - percent) / Decimal("100")
                discounted_unit_price = (unit_price * multiplier).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

            order_details_data.append({
                "product_detail_id": product_detail.id,
                "design_id": cart_detail.design_id,
                "design_snapshot_json": ProductionSnapshotService.build_design_snapshot(
                    getattr(cart_detail, "design", None),
                    product_images=list(getattr(product_detail.product, "product_images", []) or []),
                    color_id=getattr(product_detail, "color_id", None),
                ),
                "quantity": requested_quantity,
                "price": discounted_unit_price,
            })

        new_order = Order(
            user_id=user_id,
            delivery_info_id=delivery_info_id,
            payment_method_id=payment_method_id,
            status=OrderStatus.PENDING,
            payment_status=PaymentStatus.UNPAID,
            refund_support_status=RefundSupportStatus.NONE,
        )
        self.db.add(new_order)
        self.db.flush()
        if selected_discounts:
            new_order.applied_discounts.extend(selected_discounts)

        for od in order_details_data:
            detail = OrderDetail(
                order_id=new_order.id,
                product_detail_id=od["product_detail_id"],
                design_id=od["design_id"],
                design_snapshot_json=od["design_snapshot_json"],
                quantity=od["quantity"],
                price=od["price"],
            )
            self.db.add(detail)

        for cd, _, requested_qty in cart_details:
            if requested_qty < cd.quantity:
                cd.quantity = cd.quantity - requested_qty
            else:
                self.db.delete(cd)

        self.db.commit()
        self.db.refresh(new_order)
        return new_order

    def get_by_id(self, id: int) -> Optional[Any]:
        return self.db.query(Order).filter(Order.id == id).first()

    def get_by_id_with_details(self, id: int) -> Optional[Any]:
        return self._base_query().filter(Order.id == id).first()

    def get_user_orders(self, user_id: int) -> list:
        orders = (
            self._base_query()
            .filter(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .all()
        )
        return self.sync_payment_statuses(orders)

    def get_latest_order(self, user_id: int) -> Optional[Any]:
        order = (
            self._base_query()
            .filter(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .first()
        )
        if not order:
            return None
        self.sync_payment_statuses([order])
        return order

    def get_admin_orders(
        self,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> dict:
        query = self.db.query(Order)

        if keyword:
            like = f"%{keyword}%"
            conditions = [User.email.ilike(like), User.username.ilike(like)]
            if keyword.isdigit():
                conditions.append(Order.id == int(keyword))
            query = query.join(User, Order.user_id == User.id).filter(or_(*conditions))

        if status_filter:
            try:
                status_value = OrderStatus(status_filter.strip().lower())
            except ValueError:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Trạng thái không hợp lệ")
            query = query.filter(Order.status == status_value)

        total_count = query.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1: per_page = 1
            if page < 1: page = 1

        skip = (page - 1) * per_page
        items = (
            query.options(
                joinedload(Order.order_details).joinedload(OrderDetail.product_detail).joinedload(ProductDetail.product).joinedload(Product.product_images),
                joinedload(Order.order_details).joinedload(OrderDetail.product_detail).joinedload(ProductDetail.color),
                joinedload(Order.order_details).joinedload(OrderDetail.product_detail).joinedload(ProductDetail.size),
                joinedload(Order.order_details).joinedload(OrderDetail.design),
                joinedload(Order.delivery_info),
                joinedload(Order.payment_method),
                joinedload(Order.user),
                joinedload(Order.applied_discounts),
                joinedload(Order.ghn_shipments),
                joinedload(Order.vnpay_transactions),
            )
            .order_by(Order.created_at.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        self.sync_payment_statuses(items)

        last_page = math.ceil(total_count / per_page)
        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def get_user_order_by_id(self, user_id: int, order_id: int) -> Optional[Any]:
        order = (
            self._base_query()
            .filter(Order.id == order_id, Order.user_id == user_id)
            .first()
        )
        if not order:
            return None
        self.sync_payment_statuses([order])
        return order

    def get_admin_order_by_id(self, order_id: int) -> Optional[Any]:
        order = (
            self._admin_query()
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            return None
        self.sync_payment_statuses([order])
        return order

    def update_status(self, order_id: int, status: str) -> Any:
        try:
            new_status = OrderStatus(status)
        except ValueError:
            raise HTTPException(status_code=400, detail="Trạng thái không hợp lệ")

        order = self.db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status == new_status:
            self.db.refresh(order)
            return order

        if order.status == OrderStatus.PENDING and new_status == OrderStatus.SHIPPING:
            raise HTTPException(status_code=400, detail="Hãy dùng endpoint approve để duyệt đơn hàng chờ xử lý")

        if order.status == OrderStatus.PENDING and new_status == OrderStatus.CANCELLED:
            raise HTTPException(status_code=400, detail="Hãy dùng endpoint reject kèm lý do để từ chối đơn hàng cần xử lý")

        if order.status == OrderStatus.SHIPPING and new_status == OrderStatus.COMPLETED:
            order.status = new_status
            if self._is_completed_cod_order(order):
                order.payment_status = PaymentStatus.PAID
            self.db.commit()
            self.db.refresh(order)
            return order

        raise HTTPException(status_code=400, detail="Không thể chuyển trạng thái đơn hàng")

    def cancel_order(self, order_id: int, user_id: int) -> None:
        order = (
            self.db.query(Order)
            .options(joinedload(Order.order_details))
            .filter(Order.id == order_id, Order.user_id == user_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status != OrderStatus.PENDING:
            raise HTTPException(status_code=400, detail="Chỉ có thể hủy đơn hàng đang chờ xử lý")

        for od in order.order_details:
                WarehouseRepositoryImpl(self.db).increase_stock(
                    product_id=od.product_detail.product_id,
                    color_id=od.product_detail.color_id,
                    size_id=od.product_detail.size_id,
                    quantity=od.quantity,
                )

        order.status = OrderStatus.CANCELLED
        if order.payment_status == PaymentStatus.PAID:
            order.refund_support_status = RefundSupportStatus.CONTACT_REQUIRED
        self.db.commit()

    def delete_order(self, order_id: int, user_id: int) -> dict:
        self.cancel_order(order_id, user_id)
        return {"message": "Hủy đơn hàng thành công"}

    def approve_order(self, order_id: int, admin_id: int) -> Any:
        order = self.db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        order.status = OrderStatus.SHIPPING
        order.rejection_reason = None
        order.reviewed_by_admin_id = admin_id
        order.reviewed_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(order)
        return order

    def reject_order(self, order_id: int, admin_id: int, reason: str) -> Any:
        normalized = (reason or "").strip()
        if not normalized:
            raise HTTPException(status_code=400, detail="Vui lòng nhập lý do từ chối đơn")

        order = (
            self.db.query(Order)
            .options(joinedload(Order.order_details).joinedload(OrderDetail.product_detail))
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        for od in order.order_details:
            if od.product_detail:
                    WarehouseRepositoryImpl(self.db).increase_stock(
                    product_id=od.product_detail.product_id,
                    color_id=od.product_detail.color_id,
                    size_id=od.product_detail.size_id,
                    quantity=od.quantity,
                )

        order.status = OrderStatus.CANCELLED
        order.rejection_reason = normalized
        order.refund_support_status = (
            RefundSupportStatus.CONTACT_REQUIRED
            if order.payment_status == PaymentStatus.PAID
            else RefundSupportStatus.NONE
        )
        order.reviewed_by_admin_id = admin_id
        order.reviewed_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(order)
        return order

    def confirm_delivery(self, order_id: int, user_id: int) -> Any:
        order = self.db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")

        if order.status != OrderStatus.SHIPPING:
            raise HTTPException(status_code=400, detail="Chỉ có thể xác nhận khi đơn hàng đang trong quá trình giao hàng")

        order.status = OrderStatus.COMPLETED
        if self._is_completed_cod_order(order):
            order.payment_status = PaymentStatus.PAID

        self.db.commit()
        self.db.refresh(order)
        return order

    def get_order_where(self, **kwargs) -> Optional[Any]:
        return self.db.query(Order).filter_by(**kwargs).first()

    def count_by_payment_method(self, payment_method_id: int) -> int:
        return self.db.query(Order).filter(Order.payment_method_id == payment_method_id).count()

    def update_payment_status(self, order_id: int, payment_status: str) -> None:
        order = self.db.query(Order).filter(Order.id == order_id).first()
        if order:
            try:
                from app.infrastructure.database.models.order import PaymentStatus
                order.payment_status = PaymentStatus(payment_status)
            except ValueError:
                from fastapi import HTTPException
                raise HTTPException(status_code=400, detail="Trạng thái thanh toán không hợp lệ")
            self.db.commit()

    def count_orders_today(self, today: date) -> int:
        return (
            self.db.query(func.count(Order.id))
            .filter(func.date(Order.created_at) == today)
            .scalar()
            or 0
        )

    def sum_revenue_today(self, today: date) -> float:
        return (
            self.db.query(func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0))
            .join(Order, Order.id == OrderDetail.order_id)
            .filter(
                func.date(Order.created_at) == today,
                Order.status != OrderStatus.CANCELLED,
            )
            .scalar()
            or 0
        )
