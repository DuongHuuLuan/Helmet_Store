from app.domain.entities.image_url_entity import ImageUrlEntity
from app.infrastructure.database.models.image_url import ImageURL


class ImageUrlMapper:
    @staticmethod
    def to_entity(model: ImageURL) -> ImageUrlEntity:
        return ImageUrlEntity(
            id=model.id,
            product_id=model.product_id,
            url=model.url,
            public_id=model.public_id,
            color_id=model.color_id,
            view_image_key=model.view_image_key,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: ImageUrlEntity) -> ImageURL:
        return ImageURL(
            id=entity.id,
            product_id=entity.product_id,
            url=entity.url,
            public_id=entity.public_id,
            color_id=entity.color_id,
            view_image_key=entity.view_image_key,
        )
