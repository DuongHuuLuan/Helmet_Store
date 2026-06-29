from app.domain.repositories.order_repository import OrderRepository


class ConfirmDeliveryUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int, user_id: int):
        return self.order_repo.confirm_delivery(order_id, user_id)
