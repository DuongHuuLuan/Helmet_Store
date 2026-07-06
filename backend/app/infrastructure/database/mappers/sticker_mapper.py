from app.domain.entities.sticker_entity import StickerEntity


class StickerMapper:
    @staticmethod
    def to_entity(model) -> StickerEntity:
        return StickerEntity(
            id=model.id,
            owner_user_id=model.owner_user_id,
            name=model.name,
            image_url=model.image_url,
            public_id=model.public_id,
            category=model.category,
            is_ai_generated=model.is_ai_generated,
            has_transparent_background=model.has_transparent_background,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )
