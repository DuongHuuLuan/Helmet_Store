from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.profile_entity import ProfileEntity


class ProfileRepository(ABC):
    @abstractmethod
    def get_by_user_id(self, user_id: int) -> Optional[ProfileEntity]: ...

    @abstractmethod
    def get_or_create(self, user_id: int, name: str) -> ProfileEntity: ...

    @abstractmethod
    def update(self, user_id: int, data: dict) -> ProfileEntity: ...
