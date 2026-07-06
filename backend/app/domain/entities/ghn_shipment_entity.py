from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional


@dataclass
class GhnShipmentEntity:
    id: int
    order_id: int
    ghn_order_code: Optional[str] = None
    status: Optional[str] = None
    service_id: Optional[int] = None
    service_type_id: Optional[int] = None

    from_name: Optional[str] = None
    from_phone: Optional[str] = None
    from_address: Optional[str] = None
    from_ward_code: Optional[str] = None
    from_district_id: Optional[int] = None

    to_name: Optional[str] = None
    to_phone: Optional[str] = None
    to_address: Optional[str] = None
    to_ward_code: Optional[str] = None
    to_district_id: Optional[int] = None

    weight: Optional[int] = None
    length: Optional[int] = None
    width: Optional[int] = None
    height: Optional[int] = None

    cod_amount: Optional[Decimal] = None
    insurance_value: Optional[Decimal] = None
    shipping_fee: Optional[Decimal] = None

    expected_delivery_time: Optional[str] = None
    leadtime: Optional[str] = None
    tracking_url: Optional[str] = None
    note: Optional[str] = None

    raw_request: Optional[str] = None
    raw_response: Optional[str] = None

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
