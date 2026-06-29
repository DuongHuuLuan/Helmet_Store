from app.domain.repositories.order_repository import OrderRepository


class RejectOrderUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int, admin_id: int, reason: str):
        return self.order_repo.reject_order(order_id, admin_id, reason)
