from sqlalchemy import Column, Integer, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class CartDetail(Base):
    __tablename__ = "cart_details"

    id = Column(Integer, primary_key=True, index=True)
    cart_id = Column(Integer, ForeignKey("carts.id",ondelete="CASCADE"))
    product_detail_id = Column(Integer, ForeignKey("product_details.id", ondelete="CASCADE"))
    design_id = Column(Integer, ForeignKey("designs.id", ondelete="SET NULL"), nullable=True, index=True)
    quantity = Column(Integer, default=1)

    created_at = Column(DateTime(timezone=True), server_default= func.now())

    cart = relationship("Cart", back_populates="cart_details")
    product_detail = relationship("ProductDetail")
    design = relationship("Design", back_populates="cart_details")
