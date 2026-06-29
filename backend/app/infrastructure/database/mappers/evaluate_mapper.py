from app.domain.entities.evaluate_entity import EvaluateEntity, EvaluateImageEntity


class EvaluateMapper:
    @staticmethod
    def to_entity(model) -> EvaluateEntity:
        return EvaluateEntity(
            id=model.id,
            order_id=model.order_id,
            user_id=model.user_id,
            rate=model.rate,
            content=model.content,
            image=model.image,
            admin_id=model.admin_id,
            admin_reply=model.admin_reply,
            admin_replied_at=model.admin_replied_at,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )


class EvaluateImageMapper:
    @staticmethod
    def to_entity(model) -> EvaluateImageEntity:
        return EvaluateImageEntity(
            id=model.id,
            evaluate_id=model.evaluate_id,
            image_url=model.image_url,
            public_id=model.public_id,
            sort_order=model.sort_order,
            created_at=model.created_at,
        )
