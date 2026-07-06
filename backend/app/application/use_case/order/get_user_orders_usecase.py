from app.domain.repositories.order_repository import OrderRepository


class GetUserOrdersUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, user_id: int) -> list:
        return self.order_repo.get_user_orders(user_id)
