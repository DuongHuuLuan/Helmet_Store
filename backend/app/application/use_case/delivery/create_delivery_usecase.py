from app.domain.repositories.delivery_info_repository import DeliveryInfoRepository


class CreateDeliveryUseCase:
    def __init__(self, repo: DeliveryInfoRepository):
        self.repo = repo

    def execute(self, user_id: int, data: dict) -> dict:
        entity = self.repo.create(user_id, data)
        return {
            "id": entity.id,
            "user_id": entity.user_id,
            "name": entity.name,
            "address": entity.address,
            "phone": entity.phone,
            "district_id": entity.district_id,
            "ward_code": entity.ward_code,
            "default": entity.default,
        }
