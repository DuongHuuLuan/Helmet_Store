from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.infrastructure.database.base import Base


class Design(Base):
    __tablename__ = "designs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    product_detail_id = Column(
        Integer,
        ForeignKey("product_details.id", ondelete="SET NULL"),
        nullable=True,
    )
    name = Column(String(255), nullable=False)
    base_image_url = Column(String(500), nullable=False)
    preview_image_url = Column(String(500), nullable=True)
    is_shared = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="designs")
    design_product = relationship("Product", back_populates="designs")
    layers = relationship(
        "DesignLayer",
        back_populates="design",
        cascade="all, delete-orphan",
    )
    cart_details = relationship("CartDetail", back_populates="design")
    order_details = relationship("OrderDetail", back_populates="design")
    shares = relationship(
        "DesignShare",
        back_populates="design",
        cascade="all, delete-orphan",
    )
