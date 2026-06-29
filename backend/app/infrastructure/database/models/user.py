from sqlalchemy import Column, Integer, String, Boolean,DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base
import enum

class UserRole(str, enum.Enum):
    ADMIN = "admin"
    USER = "user"

class User(Base):
    __tablename__ = "users"
    username = Column(String(255),unique=True, index=True, nullable=False)
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    
    profile = relationship("Profile", back_populates="user", uselist=False)
    cart = relationship("Cart", back_populates="user", uselist = False)
    orders = relationship(
        "Order",
        back_populates="user",
        foreign_keys="Order.user_id",
    )
    reviewed_orders = relationship(
        "Order",
        back_populates="reviewing_admin",
        foreign_keys="Order.reviewed_by_admin_id",
    )
    user_conversations = relationship("Conversation", foreign_keys="Conversation.user_id", back_populates="user")
    admin_conversations = relationship("Conversation", foreign_keys="Conversation.admin_id", back_populates="admin")
    user_messages = relationship("Message", foreign_keys="Message.user_id", back_populates="user")
    
    devices = relationship("UserDevice", back_populates="user", cascade="all, delete-orphan")
    notification_jobs = relationship("NotificationOutbox", back_populates="user", cascade="all, delete-orphan")
    stickers = relationship("Sticker", back_populates="owner")
    designs = relationship("Design", back_populates="user", cascade="all, delete-orphan")

