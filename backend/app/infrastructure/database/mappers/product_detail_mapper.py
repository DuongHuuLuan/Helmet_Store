from app.domain.entities.product_detail_entity import ProductDetailEntity
from app.infrastructure.database.models.product_detail import ProductDetail


class ProductDetailMapper:
    @staticmethod
    def to_entity(model: ProductDetail) -> ProductDetailEntity:
        return ProductDetailEntity(
            id=model.id,
            product_id=model.product_id,
            color_id=model.color_id,
            size_id=model.size_id,
            price=model.price,
            is_active=model.is_active,
        )

    @staticmethod
    def to_model(entity: ProductDetailEntity) -> ProductDetail:
        return ProductDetail(
            id=entity.id,
            product_id=entity.product_id,
            color_id=entity.color_id,
            size_id=entity.size_id,
            price=entity.price,
            is_active=entity.is_active,
        )
