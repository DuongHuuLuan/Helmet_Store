from app.domain.entities.discount_entity import DiscountEntity
from app.infrastructure.database.models.discount import Discount


class DiscountMapper:
    @staticmethod
    def to_entity(model: Discount) -> DiscountEntity:
        return DiscountEntity(
            id=model.id,
            category_id=model.category_id,
            name=model.name,
            description=model.description,
            percent=model.percent,
            status=model.status.value if hasattr(model.status, 'value') else model.status,
            start_at=model.start_at,
            end_at=model.end_at,
            created_at=model.created_at,
        )
