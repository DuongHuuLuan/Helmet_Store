from app.domain.repositories.order_repository import OrderRepository


class UpdateOrderStatusUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int, status: str):
        return self.order_repo.update_status(order_id, status)
