from datetime import date

from app.domain.repositories.order_repository import OrderRepository
from app.domain.repositories.user_repository import UserRepository
from app.domain.repositories.product_repository import ProductRepository


class GetDashboardSummaryUseCase:
    def __init__(self, order_repo: OrderRepository, user_repo: UserRepository, product_repo: ProductRepository):
        self._order_repo = order_repo
        self._user_repo = user_repo
        self._product_repo = product_repo

    def execute(self) -> dict:
        today = date.today()
        return {
            "orders_today": self._order_repo.count_orders_today(today),
            "revenue_today": self._order_repo.sum_revenue_today(today),
            "total_users": self._user_repo.count_all(),
            "total_products": self._product_repo.count_all(),
        }
