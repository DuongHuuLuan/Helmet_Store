from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.infrastructure.database.models.conversation import ConversationStatus
from app.infrastructure.database.models.message import MessageType
from app.infrastructure.database.models.message_media import MessageMediaType


class ConversationCreateIn(BaseModel):
    user_id: Optional[int] = None
    admin_id: Optional[int] = None


class ChatProfileSummaryOut(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    avatar: Optional[str] = None

    class Config:
        from_attributes = True


class ChatUserSummaryOut(BaseModel):
    id: int
    username: str
    email: str
    profile: Optional[ChatProfileSummaryOut] = None

    class Config:
        from_attributes = True


class ConversationOut(BaseModel):
    id: int
    user_id: int
    admin_id: int
    user: Optional[ChatUserSummaryOut] = None
    status: ConversationStatus
    last_message_id: Optional[int] = None
    last_read_user_message_id: Optional[int] = None
    last_read_admin_message_id: Optional[int] = None
    last_read_message_id: Optional[int] = None
    unread_count: int = 0
    last_message_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MessageMediaCreate(BaseModel):
    path: str
    media_type: MessageMediaType = MessageMediaType.IMAGE


class MessageMediaOut(BaseModel):
    id: int
    path: str
    media_type: MessageMediaType
    created_at: datetime

    class Config:
        from_attributes = True

class MessageCreate(BaseModel):
    type: MessageType = MessageType.TEXT
    content: Optional[str] = None
    client_msg_id: Optional[str] = Field(default=None, max_length=64)
    media: List[MessageMediaCreate] = Field(default_factory=list)


class MessageOut(BaseModel):
    id: int
    conversation_id: int
    user_id: int
    type: MessageType
    client_msg_id: Optional[str] = None
    sender_role: Optional[str] = None
    content: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    created_at: datetime
    media_items: List[MessageMediaOut] = Field(default_factory=list)
    is_recalled: bool = False
    recalled_at: Optional[datetime] = None

    class Config:
        from_attributes = True
    
class MessageListOut(BaseModel):
    items: List[MessageOut]
    next_cursor: Optional[int] = None


class ConversationReadIn(BaseModel):
    message_id: Optional[int] = None


class ConversationReadOut(BaseModel):
    conversation_id: int
    last_read_message_id: Optional[int] = None
    unread_count: int = 0
    changed: bool = False
