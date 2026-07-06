from app.domain.entities.product_entity import ProductEntity
from app.infrastructure.database.models.product import Product


class ProductMapper:
    @staticmethod
    def to_entity(model: Product) -> ProductEntity:
        return ProductEntity(
            id=model.id,
            category_id=model.category_id,
            name=model.name,
            description=model.description,
            unit=model.unit.value if hasattr(model.unit, 'value') else model.unit,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: ProductEntity) -> Product:
        return Product(
            id=entity.id,
            category_id=entity.category_id,
            name=entity.name,
            description=entity.description,
            unit=entity.unit,
        )
