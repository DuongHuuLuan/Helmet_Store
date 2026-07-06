from typing import Any, Optional
from datetime import datetime


class MessageEntity:
    def __init__(self, id: int, conversation_id: int, user_id: int,
                 type: str = "text",
                 content: Optional[str] = None,
                 metadata_json: Optional[Any] = None,
                 client_msg_id: Optional[str] = None,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None,
                 deleted_at: Optional[datetime] = None):
        self.id = id
        self.conversation_id = conversation_id
        self.user_id = user_id
        self.type = type
        self.content = content
        self.metadata_json = metadata_json
        self.client_msg_id = client_msg_id
        self.created_at = created_at
        self.updated_at = updated_at
        self.deleted_at = deleted_at


class MessageMediaEntity:
    def __init__(self, id: int, message_id: int, path: str,
                 media_type: str = "image",
                 created_at: Optional[datetime] = None):
        self.id = id
        self.message_id = message_id
        self.path = path
        self.media_type = media_type
        self.created_at = created_at
