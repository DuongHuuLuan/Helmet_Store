from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.user_device_mapper import UserDeviceMapper
from app.domain.entities.user_device_entity import UserDeviceEntity
from app.domain.repositories.user_device_repository import UserDeviceRepository
from app.infrastructure.database.models.push_notification import UserDevice


class UserDeviceRepositoryImpl(UserDeviceRepository):
    def __init__(self, db: Session):
        self.db = db

    def list_by_user(self, user_id: int) -> list[UserDeviceEntity]:
        models = (
            self.db.query(UserDevice)
            .filter(UserDevice.user_id == user_id)
            .order_by(UserDevice.id.desc())
            .all()
        )
        return [UserDeviceMapper.to_entity(m) for m in models]

    def get_by_push_token(self, push_token: str) -> Optional[UserDeviceEntity]:
        model = (
            self.db.query(UserDevice)
            .filter(UserDevice.push_token == push_token)
            .first()
        )
        if not model:
            return None
        return UserDeviceMapper.to_entity(model)

    def get_by_user_and_device_id(self, user_id: int, device_id: str) -> Optional[UserDeviceEntity]:
        model = (
            self.db.query(UserDevice)
            .filter(
                UserDevice.user_id == user_id,
                UserDevice.device_id == device_id,
            )
            .first()
        )
        if not model:
            return None
        return UserDeviceMapper.to_entity(model)

    def create(self, user_id: int, platform: str, push_token: str,
               device_id: Optional[str] = None) -> UserDeviceEntity:
        model = UserDevice(
            user_id=user_id,
            platform=platform,
            push_token=push_token,
            device_id=device_id,
            is_active=True,
            last_seen_at=datetime.utcnow(),
        )
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return UserDeviceMapper.to_entity(model)

    def update(self, entity: UserDeviceEntity) -> UserDeviceEntity:
        model = self.db.query(UserDevice).filter(UserDevice.id == entity.id).first()
        if not model:
            return None
        model.user_id = entity.user_id
        model.platform = entity.platform
        model.device_id = entity.device_id
        model.push_token = entity.push_token
        model.is_active = entity.is_active
        model.last_seen_at = entity.last_seen_at or datetime.utcnow()
        self.db.commit()
        self.db.refresh(model)
        return UserDeviceMapper.to_entity(model)

    def deactivate_by_user_and_token(self, user_id: int, push_token: str) -> bool:
        model = (
            self.db.query(UserDevice)
            .filter(
                UserDevice.user_id == user_id,
                UserDevice.push_token == push_token,
            )
            .first()
        )
        if not model:
            return False
        model.is_active = False
        model.last_seen_at = datetime.utcnow()
        self.db.commit()
        return True

    def has_active_device(self, user_id: int) -> bool:
        return (
            self.db.query(UserDevice.id)
            .filter(
                UserDevice.user_id == user_id,
                UserDevice.is_active.is_(True),
            )
            .first()
        ) is not None

    def upsert(self, user_id: int, platform: str, push_token: str,
               device_id: Optional[str] = None) -> UserDeviceEntity:
        token = (push_token or "").strip()
        device = self.db.query(UserDevice).filter(UserDevice.push_token == token).first()
        if device:
            device.user_id = user_id
            device.platform = platform
            device.device_id = device_id
            device.is_active = True
            device.last_seen_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(device)
            return UserDeviceMapper.to_entity(device)

        if device_id:
            same_device = (
                self.db.query(UserDevice)
                .filter(
                    UserDevice.user_id == user_id,
                    UserDevice.device_id == device_id,
                )
                .first()
            )
            if same_device:
                same_device.platform = platform
                same_device.push_token = token
                same_device.is_active = True
                same_device.last_seen_at = datetime.utcnow()
                self.db.commit()
                self.db.refresh(same_device)
                return UserDeviceMapper.to_entity(same_device)

        device = UserDevice(
            user_id=user_id,
            platform=platform,
            device_id=device_id,
            push_token=token,
            is_active=True,
            last_seen_at=datetime.utcnow(),
        )
        self.db.add(device)
        self.db.commit()
        self.db.refresh(device)
        return UserDeviceMapper.to_entity(device)

    def deactivate_by_token(self, push_token: str, commit: bool = True) -> Optional[UserDeviceEntity]:
        token = (push_token or "").strip()
        if not token:
            return None
        device = self.db.query(UserDevice).filter(UserDevice.push_token == token).first()
        if not device:
            return None
        device.is_active = False
        device.last_seen_at = datetime.utcnow()
        if commit:
            self.db.commit()
        return UserDeviceMapper.to_entity(device)

    def list_active_devices(self, user_id: int) -> list[UserDeviceEntity]:
        models = (
            self.db.query(UserDevice)
            .filter(
                UserDevice.user_id == user_id,
                UserDevice.is_active.is_(True),
            )
            .all()
        )
        return [UserDeviceMapper.to_entity(m) for m in models]
