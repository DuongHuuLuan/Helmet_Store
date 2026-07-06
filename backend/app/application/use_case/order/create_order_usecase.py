from app.domain.repositories.order_repository import OrderRepository
from app.application.dto.order_dto import OrderCreate


class CreateOrderUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, user_id: int, order_in: OrderCreate):
        order_items = None
        if order_in.order_items is not None:
            order_items = [
                {
                    "cart_detail_id": item.cart_detail_id,
                    "product_detail_id": item.product_detail_id,
                    "quantity": item.quantity,
                }
                for item in order_in.order_items
            ]
        return self.order_repo.create_order(
            user_id=user_id,
            delivery_info_id=order_in.delivery_info_id,
            payment_method_id=order_in.payment_method_id,
            discount_ids=order_in.discount_ids,
            order_items=order_items,
        )
