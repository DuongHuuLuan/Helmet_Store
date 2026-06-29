from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class NotificationOutboxEntity:
    id: Optional[int] = None
    user_id: Optional[int] = None
    conversation_id: Optional[int] = None
    message_id: Optional[int] = None
    event_type: str = "chat.message.created"
    payload: str = ""
    dedupe_key: Optional[str] = None
    status: str = "pending"
    retry_count: int = 0
    max_retry: int = 5
    next_retry_at: Optional[datetime] = None
    sent_at: Optional[datetime] = None
    last_error: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
