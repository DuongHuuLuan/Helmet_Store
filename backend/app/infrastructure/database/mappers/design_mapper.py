from app.domain.entities.design_entity import DesignEntity


class DesignMapper:
    @staticmethod
    def to_entity(model) -> DesignEntity:
        return DesignEntity(
            id=model.id,
            user_id=model.user_id,
            product_id=model.product_id,
            product_detail_id=model.product_detail_id,
            name=model.name,
            base_image_url=model.base_image_url,
            preview_image_url=model.preview_image_url,
            is_shared=model.is_shared,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )
