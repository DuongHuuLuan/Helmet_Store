from typing import Optional

from app.domain.repositories.warehouse_repository import WarehouseRepository


class GetWarehousesUseCase:
    def __init__(self, repo: WarehouseRepository):
        self.repo = repo

    def execute(self, page: int = 1,
                per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        return self.repo.get_all(page=page, per_page=per_page, keyword=keyword)
