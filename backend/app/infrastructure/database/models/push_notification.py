import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Text,
    Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base


class DevicePlatform(str, enum.Enum):
    ANDROID = "android"
    IOS = "ios"
    WEB = "web"

class NotificationOutboxStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    SENT = "sent"
    FAILED = "failed"
    CANCELLED = "cancelled"


class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    platform = Column(Enum(DevicePlatform), nullable=False)
    device_id = Column(String(128), nullable=True)
    push_token = Column(String(512), nullable=False, unique=True)
    is_active = Column(Boolean, nullable=False, default=True)
    last_seen_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="devices")

    __table_args__ = (
        Index("idx_user_devices_user_active", "user_id", "is_active"),
        Index("idx_user_devices_last_seen", "last_seen_at"),
    )


class NotificationOutbox(Base):
    __tablename__ = "notification_outbox"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="SET NULL"), nullable=True, index=True)
    message_id = Column(Integer, ForeignKey("messages.id", ondelete="SET NULL"), nullable=True, index=True)

    event_type = Column(String(64), nullable=False, default="chat.message.created")
    payload = Column(Text, nullable=False)  # JSON string
    dedupe_key = Column(String(128), nullable=True, unique=True)

    status = Column(Enum(NotificationOutboxStatus), nullable=False, default=NotificationOutboxStatus.PENDING)
    retry_count = Column(Integer, nullable=False, default=0)
    max_retry = Column(Integer, nullable=False, default=5)
    next_retry_at = Column(DateTime(timezone=True), nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    last_error = Column(String(500), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="notification_jobs")
    conversation = relationship("Conversation", foreign_keys=[conversation_id], back_populates="outbox_jobs")
    message = relationship("Message", foreign_keys=[message_id], back_populates="outbox_jobs")

    __table_args__ = (
        Index("idx_outbox_poll", "status", "next_retry_at", "id"),
        Index("idx_outbox_user_created", "user_id", "created_at"),
    )
