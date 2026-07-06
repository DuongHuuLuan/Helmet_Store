from app.domain.entities.delivery_info_entity import DeliveryInfoEntity


class DeliveryInfoMapper:
    @staticmethod
    def to_entity(model) -> DeliveryInfoEntity:
        return DeliveryInfoEntity(
            id=model.id,
            user_id=model.user_id,
            name=model.name,
            address=model.address,
            phone=model.phone,
            district_id=model.district_id,
            ward_code=model.ward_code,
            default=model.default,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )
