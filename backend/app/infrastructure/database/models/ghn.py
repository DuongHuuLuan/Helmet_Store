from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, Text, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base


class GhnShipment(Base):
    __tablename__ = "ghn_shipments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    ghn_order_code = Column(String(64), index=True)
    status = Column(String(32))
    service_id = Column(Integer)
    service_type_id = Column(Integer)

    from_name = Column(String(255))
    from_phone = Column(String(20))
    from_address = Column(String(255))
    from_ward_code = Column(String(20))
    from_district_id = Column(Integer)

    to_name = Column(String(255))
    to_phone = Column(String(20))
    to_address = Column(String(255))
    to_ward_code = Column(String(20))
    to_district_id = Column(Integer)

    weight = Column(Integer)
    length = Column(Integer)
    width = Column(Integer)
    height = Column(Integer)

    cod_amount = Column(Numeric(12, 2), default=0.0)
    insurance_value = Column(Numeric(12, 2), default=0.0)
    shipping_fee = Column(Numeric(12, 2), default=0.0)

    expected_delivery_time = Column(String(64))
    leadtime = Column(String(64))
    tracking_url = Column(String(255))
    note = Column(String(255))

    raw_request = Column(Text)
    raw_response = Column(Text)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    order = relationship("Order", back_populates="ghn_shipments")
