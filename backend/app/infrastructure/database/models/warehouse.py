from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
import enum


class Warehouse(Base):
    __tablename__ = "warehouses"
    id = Column(Integer, primary_key=True, index=True)
    address = Column(String(255),nullable=False)
    capacity = Column(Integer)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

    details = relationship("WarehouseDetail", back_populates="warehouse")


class WarehouseDetail(Base):    
    __tablename__ = "warehouse_details"
    id = Column(Integer, primary_key=True, index=True)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    color_id = Column(Integer, ForeignKey("colors.id"))
    size_id = Column(Integer, ForeignKey("sizes.id"))
    quantity = Column(Integer, default=0) 

    warehouse = relationship("Warehouse", back_populates="details")
    product = relationship("Product")
    color = relationship("Color")
    size = relationship("Size")
