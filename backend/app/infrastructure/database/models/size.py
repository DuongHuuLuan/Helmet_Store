from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class Size(Base):
    __tablename__ = "sizes"

    id = Column(Integer, primary_key=True, index=True)
    size = Column(String(10), nullable=False)

    product_details = relationship("ProductDetail", back_populates="size")
    