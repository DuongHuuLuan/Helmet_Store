import enum
from sqlalchemy import (
    Column,
    Integer,
    DateTime,
    Enum,
    ForeignKey,
    UniqueConstraint,
    Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base


class ConversationStatus(str, enum.Enum):
    OPEN = "open"
    CLOSED = "closed"


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(Enum(ConversationStatus), nullable=False, default=ConversationStatus.OPEN)
    last_message_id = Column(
        Integer,
        ForeignKey(
            "messages.id",
            ondelete="SET NULL",
            use_alter=True,
            name="fk_conversations_last_message_id_messages",
        ),
        nullable=True,
    )
    last_message_at = Column(DateTime(timezone=True), nullable=True, index=True)
    last_read_user_message_id = Column(
        Integer,
        ForeignKey(
            "messages.id",
            ondelete="SET NULL",
            use_alter=True,
            name="fk_conversations_last_read_user_message_id_messages",
        ),
        nullable=True,
        index=True,
    )
    last_read_admin_message_id = Column(
        Integer,
        ForeignKey(
            "messages.id",
            ondelete="SET NULL",
            use_alter=True,
            name="fk_conversations_last_read_admin_message_id_messages",
        ),
        nullable=True,
        index=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", foreign_keys=[user_id], back_populates="user_conversations")
    admin = relationship("User", foreign_keys=[admin_id], back_populates="admin_conversations")
    messages = relationship(
        "Message",
        back_populates="conversation",
        cascade="all, delete-orphan",
        foreign_keys="Message.conversation_id",
    )
    last_message = relationship("Message", foreign_keys=[last_message_id], post_update=True)
    last_read_user_message = relationship("Message", foreign_keys=[last_read_user_message_id], post_update=True)
    last_read_admin_message = relationship("Message", foreign_keys=[last_read_admin_message_id], post_update=True)
    outbox_jobs = relationship("NotificationOutbox", back_populates="conversation")

    __table_args__ = (
        UniqueConstraint("user_id", "admin_id", name="uq_conversations_user_admin"),
        Index("idx_conversations_last_message_at", "last_message_at"),
    )
