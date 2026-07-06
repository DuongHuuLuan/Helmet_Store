from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.user_device_entity import UserDeviceEntity


class UserDeviceRepository(ABC):
    @abstractmethod
    def list_by_user(self, user_id: int) -> list[UserDeviceEntity]: ...

    @abstractmethod
    def get_by_push_token(self, push_token: str) -> Optional[UserDeviceEntity]: ...

    @abstractmethod
    def get_by_user_and_device_id(self, user_id: int, device_id: str) -> Optional[UserDeviceEntity]: ...

    @abstractmethod
    def create(self, user_id: int, platform: str, push_token: str,
               device_id: Optional[str] = None) -> UserDeviceEntity: ...

    @abstractmethod
    def update(self, entity: UserDeviceEntity) -> UserDeviceEntity: ...

    @abstractmethod
    def deactivate_by_user_and_token(self, user_id: int, push_token: str) -> bool: ...

    @abstractmethod
    def has_active_device(self, user_id: int) -> bool: ...

    @abstractmethod
    def upsert(self, user_id: int, platform: str, push_token: str,
               device_id: Optional[str] = None) -> UserDeviceEntity: ...

    @abstractmethod
    def deactivate_by_token(self, push_token: str, commit: bool = True) -> Optional[UserDeviceEntity]: ...

    @abstractmethod
    def list_active_devices(self, user_id: int) -> list[UserDeviceEntity]: ...
