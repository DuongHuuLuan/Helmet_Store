import math
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models import *
from app.models.discount import DiscountStatus
from app.models.order import OrderStatus, PaymentStatus, RefundSupportStatus
from app.schemas import *
from app.services.production_snapshot_service import ProductionSnapshotService
from app.services.warehouse_service import WarehouseService


class OrderService:
    @staticmethod
    def _base_order_query(db: Session):
        return db.query(Order).options(
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

    @staticmethod
    def _sync_payment_statuses(db: Session, orders: List[Order] | None):
        if not orders:
            return orders

        has_changes = False
        for order in orders:
            transactions = getattr(order, "vnpay_transactions", None) or []
            has_success = any((txn.status or "").strip().lower() == "success" for txn in transactions)
            next_status = (
                PaymentStatus.PAID
                if has_success or OrderService._is_completed_cod_order(order)
                else PaymentStatus.UNPAID
            )

            if order.payment_status != next_status:
                order.payment_status = next_status
                has_changes = True

        if has_changes:
            db.commit()
            for order in orders:
                db.refresh(order)

        return orders

    @staticmethod
    def _is_completed_cod_order(order: Order) -> bool:
        if getattr(order, "status", None) != OrderStatus.COMPLETED:
            return False

        payment_method = getattr(order, "payment_method", None)
        payment_method_name = str(getattr(payment_method, "name", "") or "").strip().lower()
        return "cod" in payment_method_name

    @staticmethod
    def _get_cart_for_checkout(db: Session, user_id: int) -> Cart | None:
        return (
            db.query(Cart)
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

    @staticmethod
    def _resolve_selected_cart_details(
        cart: Cart,
        order_in: OrderCreate,
    ) -> list[tuple[CartDetail, int]]:
        if order_in.order_items is None:
            return [(cart_detail, cart_detail.quantity) for cart_detail in cart.cart_details]

        if not order_in.order_items:
            raise HTTPException(status_code=400, detail="Danh sách mua không được rỗng")

        cart_details_by_id = {cart_detail.id: cart_detail for cart_detail in cart.cart_details}
        cart_details_by_product_detail: dict[int, list[CartDetail]] = {}
        for cart_detail in cart.cart_details:
            cart_details_by_product_detail.setdefault(cart_detail.product_detail_id, []).append(
                cart_detail
            )

        selected_cart_detail_ids: set[int] = set()
        selections: list[tuple[CartDetail, int]] = []

        for order_item in order_in.order_items:
            if order_item.quantity <= 0:
                raise HTTPException(status_code=400, detail="Số lượng mua phải lớn hơn 0")

            cart_detail = None
            if order_item.cart_detail_id is not None:
                cart_detail = cart_details_by_id.get(order_item.cart_detail_id)
                if cart_detail is None:
                    raise HTTPException(
                        status_code=400,
                        detail="Mục giỏ hàng không tồn tại hoặc không thuộc người dùng hiện tại",
                    )
            else:
                product_detail_id = order_item.product_detail_id or 0
                matches = cart_details_by_product_detail.get(product_detail_id, [])
                if not matches:
                    raise HTTPException(
                        status_code=400,
                        detail="Sản phẩm không có trong giỏ hàng",
                    )
                if len(matches) > 1:
                    raise HTTPException(
                        status_code=400,
                        detail=(
                            "Biến thể sản phẩm này có nhiều mục trong giỏ hàng. "
                            "Vui lòng gửi cart_detail_id để chọn đúng mục cần đặt."
                        ),
                    )
                cart_detail = matches[0]

            if cart_detail.id in selected_cart_detail_ids:
                raise HTTPException(status_code=400, detail="Trùng mục giỏ hàng trong danh sách mua")

            if order_item.quantity > cart_detail.quantity:
                product_name = (
                    cart_detail.product_detail.product.name
                    if cart_detail.product_detail and cart_detail.product_detail.product
                    else "Sản phẩm"
                )
                raise HTTPException(
                    status_code=400,
                    detail=f"Số lượng mua vượt quá số lượng trong giỏ hàng: {product_name}",
                )

            selected_cart_detail_ids.add(cart_detail.id)
            selections.append((cart_detail, order_item.quantity))

        return selections

    @staticmethod
    def create_order(db: Session, user_id: int, order_in: OrderCreate):
        cart = OrderService._get_cart_for_checkout(db, user_id)
        if not cart or not cart.cart_details:
            raise HTTPException(status_code=400, detail="Giỏ hàng trống")

        selected_items = OrderService._resolve_selected_cart_details(cart, order_in)

        total_price = Decimal("0")
        order_details_to_create = []
        cart_details = []

        for cart_detail, requested_quantity in selected_items:
            product_detail = cart_detail.product_detail
            if not product_detail:
                raise HTTPException(
                    status_code=400,
                    detail=f"Sản phẩm ID {cart_detail.product_detail_id} không còn tồn tại",
                )

            available_quantity = WarehouseService.get_total_stock(db, product_detail)
            if available_quantity < requested_quantity:
                product_name = (
                    product_detail.product.name
                    if product_detail.product
                    else f"ID {cart_detail.product_detail_id}"
                )
                raise HTTPException(
                    status_code=400,
                    detail=f"Sản phẩm {product_name} không đủ hàng",
                )

            cart_details.append((cart_detail, product_detail, requested_quantity))
            WarehouseService.decrease_stock(db, product_detail, requested_quantity)

        category_ids = {
            product_detail.product.category_id
            for _, product_detail, _ in cart_details
            if product_detail.product and product_detail.product.category_id
        }
        category_discounts = {}
        selected_discounts = []

        if order_in.discount_ids is None:
            from app.services.discount_service import DiscountService

            category_discounts = DiscountService.get_valid_discounts_by_category_ids(
                db,
                category_ids,
            )
            selected_discounts = list(category_discounts.values())
        else:
            raw_discount_ids = [int(discount_id) for discount_id in order_in.discount_ids]
            unique_discount_ids = list(dict.fromkeys(raw_discount_ids))
            if unique_discount_ids:
                now = datetime.now()
                valid_discounts = db.query(Discount).filter(
                    Discount.id.in_(unique_discount_ids),
                    Discount.status == DiscountStatus.ACTIVE,
                    Discount.start_at <= now,
                    Discount.end_at >= now,
                ).all()

                valid_by_id = {discount.id: discount for discount in valid_discounts}
                missing_ids = [
                    discount_id
                    for discount_id in unique_discount_ids
                    if discount_id not in valid_by_id
                ]
                if missing_ids:
                    raise HTTPException(
                        status_code=400,
                        detail="Có mã giảm giá không hợp lệ hoặc đã hết hạn",
                    )

                for discount_id in unique_discount_ids:
                    discount = valid_by_id[discount_id]
                    if discount.category_id not in category_ids:
                        raise HTTPException(
                            status_code=400,
                            detail=f"Mã giảm giá {discount.name} không áp dụng cho sản phẩm đã chọn",
                        )
                    if discount.category_id in category_discounts:
                        raise HTTPException(
                            status_code=400,
                            detail="Chỉ được chọn một mã giảm giá cho mỗi danh mục",
                        )
                    category_discounts[discount.category_id] = discount
                    selected_discounts.append(discount)

        for cart_detail, product_detail, requested_quantity in cart_details:
            unit_price = Decimal(str(product_detail.price or 0))
            discount = None
            if product_detail.product:
                discount = category_discounts.get(product_detail.product.category_id)

            discounted_unit_price = unit_price
            if discount:
                percent = Decimal(str(discount.percent))
                discount_multiplier = (Decimal("100") - percent) / Decimal("100")
                discounted_unit_price = (unit_price * discount_multiplier).quantize(
                    Decimal("0.01"),
                    rounding=ROUND_HALF_UP,
                )

            total_price += discounted_unit_price * requested_quantity
            order_details_to_create.append(
                {
                    "product_detail_id": product_detail.id,
                    "design_id": cart_detail.design_id,
                    "design_snapshot_json": ProductionSnapshotService.build_design_snapshot(
                        getattr(cart_detail, "design", None),
                        product_images=list(
                            getattr(product_detail.product, "product_images", []) or []
                        ),
                        color_id=getattr(product_detail, "color_id", None),
                    ),
                    "quantity": requested_quantity,
                    "price": discounted_unit_price,
                }
            )

        new_order = Order(
            user_id=user_id,
            delivery_info_id=order_in.delivery_info_id,
            payment_method_id=order_in.payment_method_id,
            status=OrderStatus.PENDING,
            payment_status=PaymentStatus.UNPAID,
            refund_support_status=RefundSupportStatus.NONE,
        )
        db.add(new_order)
        db.flush()
        if selected_discounts:
            new_order.applied_discounts.extend(selected_discounts)

        for order_detail in order_details_to_create:
            detail = OrderDetail(
                order_id=new_order.id,
                product_detail_id=order_detail["product_detail_id"],
                design_id=order_detail["design_id"],
                design_snapshot_json=order_detail["design_snapshot_json"],
                quantity=order_detail["quantity"],
                price=order_detail["price"],
            )
            db.add(detail)

        for cart_detail, _, requested_quantity in cart_details:
            if requested_quantity < cart_detail.quantity:
                cart_detail.quantity = cart_detail.quantity - requested_quantity
            else:
                db.delete(cart_detail)

        db.commit()
        db.refresh(new_order)
        return new_order

    @staticmethod
    def get_orders(db: Session, user_id: int) -> List[Order]:
        orders = (
            OrderService._base_order_query(db)
            .filter(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .all()
        )
        return OrderService._sync_payment_statuses(db, orders)

    # Hàm truy vấn đơn hàng mới nhất của một người dùng cụ thể
    @staticmethod
    def get_latest_order(db: Session, user_id: int) -> Optional[Order]:
        order = (
            OrderService._base_order_query(db)
            .filter(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .first()
        )
        if not order:
            return None

        OrderService._sync_payment_statuses(db, [order])
        return order


    @staticmethod
    def get_orders2(db: Session, user_id: int) -> List[Order]:
        return db.query(Order).filter(Order.user_id == user_id).all()

    @staticmethod
    def get_order_byID(db: Session, order_id: int, user_id: int):
        order = (
            OrderService._base_order_query(db)
            .filter(Order.id == order_id, Order.user_id == user_id)
            .first()
        )

        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
        OrderService._sync_payment_statuses(db, [order])
        return order

    @staticmethod
    def get_admin_orders(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        status_filter: Optional[str] = None,
    ):
        query = db.query(Order)

        if keyword:
            like = f"%{keyword}%"
            conditions = [User.email.ilike(like), User.username.ilike(like)]
            if keyword.isdigit():
                conditions.append(Order.id == int(keyword))
            query = query.join(User, Order.user_id == User.id).filter(or_(*conditions))

        if status_filter:
            try:
                status_value = OrderStatus(status_filter.strip().lower())
            except ValueError as exc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Trạng thái không hợp lệ",
                ) from exc
            query = query.filter(Order.status == status_value)

        total_count = query.count()
        if total_count == 0:
            return {
                "items": [],
                "meta": {
                    "total": 0,
                    "current_page": 1,
                    "per_page": per_page or 0,
                    "last_page": 1,
                },
            }

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        items = (
            query.options(
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
            .order_by(Order.created_at.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        OrderService._sync_payment_statuses(db, items)

        last_page = math.ceil(total_count / per_page)
        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }

    @staticmethod
    def get_admin_order_by_id(db: Session, order_id: int):
        order = (
            db.query(Order)
            .options(
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
            .filter(Order.id == order_id)
            .first()
        )

        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
        OrderService._sync_payment_statuses(db, [order])
        return order

    @staticmethod
    def update_status(db: Session, order_id: int, status: OrderStatus):
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status == status:
            db.refresh(order)
            return order

        if order.status == OrderStatus.PENDING and status == OrderStatus.SHIPPING:
            raise HTTPException(
                status_code=400,
                detail="Hãy dùng endpoint approve để duyệt đơn hàng chờ xử lý",
            )

        if order.status == OrderStatus.PENDING and status == OrderStatus.CANCELLED:
            raise HTTPException(
                status_code=400,
                detail="Hãy dùng endpoint reject kèm lý do để từ chối đơn hàng cần xử lý",
            )

        if order.status == OrderStatus.SHIPPING and status == OrderStatus.COMPLETED:
            order.status = status
            if OrderService._is_completed_cod_order(order):
                order.payment_status = PaymentStatus.PAID
            db.commit()
            db.refresh(order)
            return order

    @staticmethod
    def approve_order(db: Session, order_id: int, admin_id: int):
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        order.status = OrderStatus.SHIPPING
        order.rejection_reason = None
        order.refund_support_status = RefundSupportStatus.NONE
        order.reviewed_by_admin_id = admin_id
        order.reviewed_at = datetime.utcnow()
        db.commit()
        db.refresh(order)
        return order

    @staticmethod
    def reject_order(db: Session, order_id: int, admin_id: int, reason: str):
        normalized_reason = (reason or "").strip()
        if not normalized_reason:
            raise HTTPException(status_code=400, detail="Vui lòng nhập lý do từ chối đơn")

        order = (
            db.query(Order)
            .options(joinedload(Order.order_details).joinedload(OrderDetail.product_detail))
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        for order_detail in order.order_details:
            if order_detail.product_detail:
                WarehouseService.increase_stock(db, order_detail.product_detail, order_detail.quantity)

        order.status = OrderStatus.CANCELLED
        order.rejection_reason = normalized_reason
        order.refund_support_status = (
            RefundSupportStatus.CONTACT_REQUIRED
            if order.payment_status == PaymentStatus.PAID
            else RefundSupportStatus.NONE
        )
        order.reviewed_by_admin_id = admin_id
        order.reviewed_at = datetime.utcnow()
        db.commit()
        db.refresh(order)
        return order

    @staticmethod
    def delete_order(db: Session, order_id: int, user_id: int):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status != OrderStatus.PENDING:
            raise HTTPException(status_code=400, detail="Chỉ có thể hủy đơn hàng đang chờ xử lý")
        for order_detail in order.order_details:
            WarehouseService.increase_stock(db, order_detail.product_detail, order_detail.quantity)

        order.status = OrderStatus.CANCELLED
        if order.payment_status == PaymentStatus.PAID:
            order.refund_support_status = RefundSupportStatus.CONTACT_REQUIRED
        db.commit()
        return {"message": "Hủy đơn hàng thành công"}

    @staticmethod
    def confirm_delivery(db: Session, order_id: int, user_id: int):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()

        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")

        if order.status != OrderStatus.SHIPPING:
            raise HTTPException(
                status_code=400,
                detail="Chỉ có thể xác nhận khi đơn hàng đang trong quá trình giao hàng",
            )
        order.status = OrderStatus.COMPLETED
        if OrderService._is_completed_cod_order(order):
            order.payment_status = PaymentStatus.PAID

        db.commit()
        db.refresh(order)
        return order
