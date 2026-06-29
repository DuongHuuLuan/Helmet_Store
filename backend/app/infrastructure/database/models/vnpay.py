from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base


class VnPayTransaction(Base):
    __tablename__ = "vnpay_transactions"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    txn_ref = Column(String(64), index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    response_code = Column(String(8))
    status = Column(String(32))
    transaction_no = Column(String(32))
    bank_code = Column(String(20))
    pay_date = Column(String(32))   
    message = Column(String(255))

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    order = relationship("Order", back_populates="vnpay_transactions")
