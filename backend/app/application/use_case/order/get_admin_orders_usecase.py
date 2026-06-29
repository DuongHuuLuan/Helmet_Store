from typing import Optional

from app.domain.repositories.order_repository import OrderRepository


class GetAdminOrdersUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(
        self,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> dict:
        return self.order_repo.get_admin_orders(
            page=page,
            per_page=per_page,
            keyword=keyword,
            status_filter=status_filter,
        )
