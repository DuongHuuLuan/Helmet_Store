from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.conversation_entity import ConversationEntity


class ConversationRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[ConversationEntity]: ...

    @abstractmethod
    def get_by_user_admin(self, user_id: int, admin_id: int) -> Optional[ConversationEntity]: ...

    @abstractmethod
    def list_by_user_id(self, user_id: int) -> list[ConversationEntity]: ...

    @abstractmethod
    def list_by_admin_id(self, admin_id: int) -> list[ConversationEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> ConversationEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> ConversationEntity: ...

    @abstractmethod
    def mark_as_read(self, id: int, last_read_user_message_id: Optional[int] = None,
                     last_read_admin_message_id: Optional[int] = None) -> Optional[ConversationEntity]: ...

    @abstractmethod
    def update_status(self, id: int, status: str) -> Optional[ConversationEntity]: ...

    @abstractmethod
    def get_conversation_with_user(self, id: int) -> Optional[ConversationEntity]: ...

    @abstractmethod
    def create_or_get(self, user_id: int, admin_id: int) -> ConversationEntity: ...
