from typing import Optional

from app.domain.repositories.warehouse_repository import WarehouseRepository


class GetWarehouseDetailUseCase:
    def __init__(self, repo: WarehouseRepository):
        self.repo = repo

    def execute(self, warehouse_id: int,
                page: int = 1,
                per_page: Optional[int] = None,
                keyword: Optional[str] = None,
                category_id: Optional[int] = None) -> dict:
        return self.repo.get_detail_list(
            warehouse_id,
            page=page,
            per_page=per_page,
            keyword=keyword,
            category_id=category_id,
        )
