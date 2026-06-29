
from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
from datetime import datetime

class DeliveryInfo(Base):
    __tablename__ = "delivery_info"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255))
    address = Column(String(255))
    phone = Column(String(20))
    district_id = Column(Integer, nullable=True)
    ward_code = Column(String(20), nullable=True)
    default = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


    orders = relationship("Order", back_populates="delivery_info")
