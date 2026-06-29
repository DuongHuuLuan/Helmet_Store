from sqlalchemy import Boolean, Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class ProductDetail(Base):
    __tablename__ = "product_details"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"))
    color_id = Column(Integer, ForeignKey("colors.id"))
    size_id = Column(Integer, ForeignKey("sizes.id"))
    price = Column(Integer, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    
    product = relationship("Product", back_populates="product_details")
    color = relationship("Color", back_populates="product_details")
    size = relationship("Size", back_populates="product_details")

    order_details = relationship("OrderDetail", back_populates="product_detail")
    cart_details = relationship("CartDetail", back_populates="product_detail")