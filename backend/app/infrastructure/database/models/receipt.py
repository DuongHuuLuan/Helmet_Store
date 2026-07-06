from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
import enum


class ReceiptStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Receipt(Base):
    __tablename__ = "receipts"
    id = Column(Integer, primary_key=True, index=True)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"))
    distributor_id = Column(Integer, ForeignKey("distributors.id"))
    status = Column(Enum(ReceiptStatus), default=ReceiptStatus.PENDING)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    details = relationship("ReceiptDetail", back_populates="receipt")
    warehouse = relationship("Warehouse")
    distributor = relationship("Distributor")


class ReceiptDetail(Base):
    __tablename__ = "receipt_details"
    id = Column(Integer, primary_key=True, index=True)
    receipt_id = Column(Integer, ForeignKey("receipts.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    color_id = Column(Integer, ForeignKey("colors.id"))
    size_id = Column(Integer, ForeignKey("sizes.id"))
    quantity = Column(Integer, nullable=False)
    purchase_price = Column(Numeric(10, 2), nullable=False)

    receipt = relationship("Receipt", back_populates="details")
    product = relationship("Product")
    color = relationship("Color")
    size = relationship("Size")
