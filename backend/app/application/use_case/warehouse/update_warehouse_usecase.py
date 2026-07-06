from app.domain.repositories.warehouse_repository import WarehouseRepository
from app.application.dto.warehouse_dto import WarehouseCreate


class UpdateWarehouseUseCase:
    def __init__(self, repo: WarehouseRepository):
        self.repo = repo

    def execute(self, warehouse_id: int,
                warehouse_in: WarehouseCreate) -> dict:
        entity = self.repo.update(warehouse_id, warehouse_in.model_dump())
        return {
            "id": entity.id,
            "address": entity.address,
            "capacity": entity.capacity,
            "products_count": 0,
            "total_quantity": 0,
            "pending_quantity": 0,
        }
