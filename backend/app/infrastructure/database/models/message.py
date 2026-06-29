import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Enum,
    ForeignKey,
    Text,
    UniqueConstraint,
    Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base


class MessageType(str, enum.Enum):
    TEXT = "text"
    IMAGE = "image"
    FILE = "file"
    SYSTEM = "system"


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    type = Column(Enum(MessageType), nullable=False, default=MessageType.TEXT)
    content = Column(Text, nullable=True)
    metadata_json = Column("metadata", Text, nullable=True)
    client_msg_id = Column(String(64), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    conversation = relationship("Conversation", back_populates="messages", foreign_keys=[conversation_id])
    user = relationship("User", foreign_keys=[user_id], back_populates="user_messages")
    media_items = relationship("MessageMedia", back_populates="message", cascade="all, delete-orphan")
    outbox_jobs = relationship("NotificationOutbox", back_populates="message")

    __table_args__ = (
        UniqueConstraint("user_id", "client_msg_id", name="uq_messages_user_client_msg"),
        Index("idx_messages_conversation_created_at", "conversation_id", "created_at"),
    )
