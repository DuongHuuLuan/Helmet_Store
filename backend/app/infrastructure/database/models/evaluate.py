from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, Text, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class Evaluate(Base):
    __tablename__ = "evaluates"
    __table_args__ = (
        UniqueConstraint("order_id", name="uq_evaluates_order_id"),
    )

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    rate = Column(Integer, nullable=False) # 1-5 sao
    content = Column(String(255), nullable=True)
    image = Column(String(255), nullable=True)

    admin_reply = Column(Text, nullable = True)
    admin_replied_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)


    order = relationship("Order", backref="evaluation")
    user = relationship("User", foreign_keys=[user_id], backref="evaluations")
    admin = relationship("User", foreign_keys=[admin_id], backref="evaluate_replies")
    images = relationship("EvaluateImage", back_populates="evaluate", cascade="all, delete-orphan")
