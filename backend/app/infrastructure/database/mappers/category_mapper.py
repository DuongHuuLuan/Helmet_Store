from app.domain.entities.category_entity import CategoryEntity
from app.infrastructure.database.models.category import Category


class CategoryMapper:
    @staticmethod
    def to_entity(model: Category) -> CategoryEntity:
        return CategoryEntity(
            id=model.id,
            name=model.name,
            created_at=model.created_at,
        )
