from app.domain.repositories.discount_repository import DiscountRepository


class UpdateDiscountUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, discount_id: int, data: dict) -> dict:
        entity = self.repo.update(discount_id, data)
        return {
            "id": entity.id, "category_id": entity.category_id,
            "name": entity.name, "description": entity.description,
            "percent": entity.percent, "status": entity.status,
            "start_at": entity.start_at, "end_at": entity.end_at,
            "created_at": entity.created_at,
        }
