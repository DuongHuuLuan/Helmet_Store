from app.domain.repositories.order_repository import OrderRepository


class ApproveOrderUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int, admin_id: int):
        return self.order_repo.approve_order(order_id, admin_id)
