from app.domain.repositories.discount_repository import DiscountRepository
from app.domain.entities.discount_entity import DiscountEntity


class CreateDiscountUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, data: dict) -> dict:
        entity = self.repo.create(data)
        return {
            "id": entity.id, "category_id": entity.category_id,
            "name": entity.name, "description": entity.description,
            "percent": entity.percent, "status": entity.status,
            "start_at": entity.start_at, "end_at": entity.end_at,
            "created_at": entity.created_at, "can_delete": True,
        }
