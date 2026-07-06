from fastapi import HTTPException, status

from app.domain.repositories.warehouse_repository import WarehouseRepository


class GetWarehouseUseCase:
    def __init__(self, repo: WarehouseRepository):
        self.repo = repo

    def execute(self, warehouse_id: int):
        result = self.repo.get_with_summary(warehouse_id)
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kho không tồn tại",
            )
        return result
