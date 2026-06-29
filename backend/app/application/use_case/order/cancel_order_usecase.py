from app.domain.repositories.order_repository import OrderRepository


class CancelOrderUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int, user_id: int) -> dict:
        self.order_repo.cancel_order(order_id, user_id)
        return {"message": "Hủy đơn hàng thành công"}
