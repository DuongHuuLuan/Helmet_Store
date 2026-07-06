from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.infrastructure.database.base import Base


class Sticker(Base):
    __tablename__ = "stickers"

    id = Column(Integer, primary_key=True, index=True)
    owner_user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    name = Column(String(255), nullable=False)
    image_url = Column(String(500), nullable=False)
    public_id = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False, default="General")
    is_ai_generated = Column(Boolean, default=False, nullable=False)
    has_transparent_background = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    owner = relationship("User", back_populates="stickers")
    design_layers = relationship("DesignLayer", back_populates="sticker")
