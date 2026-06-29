from abc import ABC, abstractmethod
from typing import Any, Optional
from app.domain.entities.message_entity import MessageEntity


class MessageRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[MessageEntity]: ...

    @abstractmethod
    def list_by_conversation_id(self, conversation_id: int, cursor: Optional[int] = None,
                                limit: int = 20) -> tuple[list[MessageEntity], Optional[int]]: ...

    @abstractmethod
    def create(self, data: dict) -> MessageEntity: ...

    @abstractmethod
    def create_bulk(self, data_list: list[dict]) -> list[MessageEntity]: ...

    @abstractmethod
    def soft_delete(self, id: int) -> MessageEntity: ...

    @abstractmethod
    def get_latest_message_id(self, conversation_id: int, exclude_user_id: int,
                               max_id: Optional[int] = None) -> Optional[int]: ...

    @abstractmethod
    def get_latest_message_for_conversation(self, conversation_id: int) -> Optional[MessageEntity]: ...

    @abstractmethod
    def count_unread(self, conversation_id: int, exclude_user_id: int,
                      last_read_id: Optional[int]) -> int: ...

    @abstractmethod
    def count_unread_bulk(self, conversation_ids: list[int], exclude_user_id: int,
                           last_read_map: dict[int, Optional[int]]) -> dict[int, int]: ...

    @abstractmethod
    def get_recent_messages(self, conversation_id: int, limit: int,
                            exclude_deleted: bool = True) -> list: ...

    @abstractmethod
    def find_existing_bot_reply(self, conversation_id: int, admin_id: int,
                                user_message_id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_by_id_with_media(self, message_id: int,
                             conversation_id: int) -> Optional[Any]: ...
