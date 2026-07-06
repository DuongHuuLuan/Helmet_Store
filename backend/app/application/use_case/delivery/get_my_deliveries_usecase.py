from app.domain.repositories.delivery_info_repository import DeliveryInfoRepository


class GetMyDeliveriesUseCase:
    def __init__(self, repo: DeliveryInfoRepository):
        self.repo = repo

    def execute(self, user_id: int) -> list[dict]:
        entities = self.repo.get_by_user_id(user_id)
        return [
            {
                "id": e.id,
                "user_id": e.user_id,
                "name": e.name,
                "address": e.address,
                "phone": e.phone,
                "district_id": e.district_id,
                "ward_code": e.ward_code,
                "default": e.default,
            }
            for e in entities
        ]
