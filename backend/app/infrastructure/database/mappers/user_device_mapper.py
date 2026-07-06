from app.domain.entities.user_device_entity import UserDeviceEntity
from app.infrastructure.database.models.push_notification import UserDevice


class UserDeviceMapper:
    @staticmethod
    def to_entity(model: UserDevice) -> UserDeviceEntity:
        return UserDeviceEntity(
            id=model.id,
            user_id=model.user_id,
            platform=model.platform.value if hasattr(model.platform, 'value') else model.platform,
            push_token=model.push_token,
            device_id=model.device_id,
            is_active=model.is_active,
            last_seen_at=model.last_seen_at,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: UserDeviceEntity) -> UserDevice:
        return UserDevice(
            id=entity.id,
            user_id=entity.user_id,
            platform=entity.platform,
            push_token=entity.push_token,
            device_id=entity.device_id,
            is_active=entity.is_active,
            last_seen_at=entity.last_seen_at,
        )
