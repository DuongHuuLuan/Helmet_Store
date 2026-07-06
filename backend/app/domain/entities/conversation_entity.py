from typing import Optional
from datetime import datetime


class ConversationEntity:
    def __init__(self, id: int, user_id: int, admin_id: int,
                 status: str = "open",
                 last_message_id: Optional[int] = None,
                 last_message_at: Optional[datetime] = None,
                 last_read_user_message_id: Optional[int] = None,
                 last_read_admin_message_id: Optional[int] = None,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None,
                 last_read_message_id: Optional[int] = None,
                 unread_count: int = 0):
        self.id = id
        self.user_id = user_id
        self.admin_id = admin_id
        self.status = status
        self.last_message_id = last_message_id
        self.last_message_at = last_message_at
        self.last_read_user_message_id = last_read_user_message_id
        self.last_read_admin_message_id = last_read_admin_message_id
        self.created_at = created_at
        self.updated_at = updated_at
        self.last_read_message_id = last_read_message_id
        self.unread_count = unread_count
