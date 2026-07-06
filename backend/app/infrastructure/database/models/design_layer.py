from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.infrastructure.database.base import Base


class DesignLayer(Base):
    __tablename__ = "design_layers"

    id = Column(Integer, primary_key=True, index=True)
    design_id = Column(
        Integer,
        ForeignKey("designs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    sticker_id = Column(Integer, ForeignKey("stickers.id"), nullable=False)
    image_url = Column(String(500), nullable=False)
    x = Column(Float, default=0.0, nullable=False)
    y = Column(Float, default=0.0, nullable=False)
    scale = Column(Float, default=1.0, nullable=False)
    rotation = Column(Float, default=0.0, nullable=False)
    z_index = Column(Integer, default=0, nullable=False)
    view_image_key = Column(String(50), nullable=True)
    tint_color_value = Column(Integer, nullable=True)
    crop_left = Column(Float, default=0.0, nullable=False)
    crop_top = Column(Float, default=0.0, nullable=False)
    crop_right = Column(Float, default=1.0, nullable=False)
    crop_bottom = Column(Float, default=1.0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    design = relationship("Design", back_populates="layers")
    sticker = relationship("Sticker", back_populates="design_layers")
