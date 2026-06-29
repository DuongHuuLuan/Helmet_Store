from fastapi import HTTPException, status
from app.domain.repositories.delivery_info_repository import DeliveryInfoRepository


class DeleteDeliveryUseCase:
    def __init__(self, repo: DeliveryInfoRepository):
        self.repo = repo

    def execute(self, delivery_id: int, user_id: int) -> dict:
        entity = self.repo.get_by_id(delivery_id)
        if not entity:
            raise HTTPException(status_code=404, detail="Không tìm thấy địa chỉ giao hàng")
        self.repo.delete(delivery_id, user_id)
        return {"message": "Xóa địa chỉ giao hàng thành công"}
