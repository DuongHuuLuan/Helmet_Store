from  sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base

class ImageURL(Base):
    __tablename__ = "image_url"

    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    color_id = Column(Integer, ForeignKey("colors.id"))
    url = Column(String(255), nullable=False)
    public_id = Column(String(255), nullable=False)
    view_image_key = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    
    product = relationship("Product", back_populates="product_images")
    color = relationship("Color", back_populates="images")
