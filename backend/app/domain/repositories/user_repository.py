from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.user_entity import UserEntity


class UserRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[UserEntity]: ...

    @abstractmethod
    def get_by_email(self, email: str) -> Optional[UserEntity]: ...

    @abstractmethod
    def get_by_username(self, username: str) -> Optional[UserEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, role: Optional[str] = None) -> dict: ...

    @abstractmethod
    def create(self, email: str, username: str, password: str, role: str = "user") -> UserEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> UserEntity: ...

    @abstractmethod
    def exists_by_email(self, email: str, exclude_id: Optional[int] = None) -> bool: ...

    @abstractmethod
    def exists_by_username(self, username: str, exclude_id: Optional[int] = None) -> bool: ...

    @abstractmethod
    def get_first_by_role(self, role: str) -> Optional[UserEntity]: ...

    @abstractmethod
    def count_all(self) -> int: ...
