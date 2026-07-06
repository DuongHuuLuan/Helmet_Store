from app.domain.repositories.warehouse_repository import WarehouseRepository


class DeleteWarehouseUseCase:
    def __init__(self, repo: WarehouseRepository):
        self.repo = repo

    def execute(self, warehouse_id: int) -> dict:
        self.repo.delete(warehouse_id)
        return {"message": "Đã xóa kho thành công"}
