from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Numeric, Enum, func, JSON
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
import enum
from datetime import datetime

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    SHIPPING = "shipping"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PaymentStatus(str, enum.Enum):
    UNPAID = "unpaid"
    PAID = "paid"


class RefundSupportStatus(str, enum.Enum):
    NONE = "none"
    CONTACT_REQUIRED = "contact_required"
    RESOLVED = "resolved"


def _enum_values(enum_cls):
    return [member.value for member in enum_cls]


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    delivery_info_id = Column(Integer, ForeignKey("delivery_info.id"))
    payment_method_id = Column(Integer, ForeignKey("payment_methods.id"))
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING)
    payment_status = Column(
        Enum(PaymentStatus, values_callable=_enum_values),
        default=PaymentStatus.UNPAID,
        nullable=False,
    )
    refund_support_status = Column(
        Enum(RefundSupportStatus, values_callable=_enum_values),
        default=RefundSupportStatus.NONE,
        nullable=False,
    )
    rejection_reason = Column(String(500), nullable=True)
    reviewed_by_admin_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship(
        "User",
        back_populates="orders",
        foreign_keys=[user_id],
    )
    reviewing_admin = relationship(
        "User",
        back_populates="reviewed_orders",
        foreign_keys=[reviewed_by_admin_id],
    )
    order_details = relationship("OrderDetail", back_populates="order", cascade="all, delete-orphan")
    delivery_info = relationship("DeliveryInfo", back_populates="orders")
    payment_method = relationship("PaymentMethod", back_populates="orders")
    vnpay_transactions = relationship(
        "VnPayTransaction",
        back_populates="order",
        cascade="all, delete-orphan",
    )
    ghn_shipments = relationship(
        "GhnShipment",
        back_populates="order",
        cascade="all, delete-orphan",
    )

    applied_discounts = relationship(
        "Discount", 
        secondary="order_discounts", 
        back_populates="orders"
    )


class OrderDetail(Base):
    __tablename__ = "order_details"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"))
    product_detail_id = Column(Integer, ForeignKey("product_details.id"))
    design_id = Column(Integer, ForeignKey("designs.id", ondelete="SET NULL"), nullable=True, index=True)
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10,2), nullable=False)
    design_snapshot_json = Column(JSON, nullable=True)

    order = relationship("Order", back_populates="order_details")
    product_detail = relationship("ProductDetail")
    design = relationship("Design", back_populates="order_details")
