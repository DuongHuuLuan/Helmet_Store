from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.infrastructure.database.base import Base
import enum

class UnitEnum(str, enum.Enum):
    CAI = "Cái"
    CHIEC = "Chiếc"
    BO = "Bộ"
    COMBO = "ComBo"

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey("categories.id"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    unit = Column(Enum(UnitEnum), default=UnitEnum.CHIEC, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    category = relationship("Category", back_populates="products")
    product_images = relationship("ImageURL", back_populates="product", cascade="all, delete")
    
    product_details = relationship("ProductDetail", back_populates="product", cascade="all, delete-orphan")
    designs = relationship("Design", back_populates="design_product")
