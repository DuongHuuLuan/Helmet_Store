import enum
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, DECIMAL, Enum, Text
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
from datetime import datetime

class DiscountStatus(str, enum.Enum):
    ACTIVE = "active"
    EXPIRED = "expired"
    DISABLED = "disabled"

class Discount(Base):
    __tablename__ = "discounts"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    percent = Column(DECIMAL(5,2), nullable=False)
    status = Column(Enum(DiscountStatus), default=DiscountStatus.ACTIVE)
    start_at = Column(DateTime, nullable=False)
    end_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.now)

    category = relationship("Category", back_populates="discounts")

    
    orders = relationship(
        "Order", 
        secondary="order_discounts", 
        back_populates="applied_discounts"
    )

class OrderDiscount(Base):
    __tablename__ = "order_discounts"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    discount_id = Column(Integer, ForeignKey("discounts.id", ondelete="CASCADE"), nullable=False)

    # order = relationship("Order", back_populates="applied_discounts")
    # discount = relationship("Discount")
