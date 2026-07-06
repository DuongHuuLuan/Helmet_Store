from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class Color(Base):
    __tablename__ = "colors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    hexcode = Column(String(10), nullable=False)

    product_details = relationship("ProductDetail", back_populates="color")
    images = relationship("ImageURL", back_populates="color")



