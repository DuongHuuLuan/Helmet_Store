from decimal import Decimal
from typing import Optional
from pydantic import BaseModel


class GhnFeeRequest(BaseModel):
    order_id: Optional[int] = None
    to_district_id: int #id địa chỉ
    to_ward_code: str # địa chỉ
    service_id: Optional[int] = None
    service_type_id: Optional[int] = None
    insurance_value: Optional[Decimal] = None


class GhnFeeOut(BaseModel):
    total: Decimal # tổng phí ship cuối cùng
    service_fee: Optional[Decimal] = None #cước phí vận chuyển thuần
    insurance_fee: Optional[Decimal] = None # phí bảo hiểm


class GhnCreateOrderRequest(BaseModel):
    order_id: int
    to_district_id: int
    to_ward_code: str
    service_id: Optional[int] = None
    service_type_id: Optional[int] = None
    note: Optional[str] = None 
    required_note: Optional[str] = None
    cod_amount: Optional[Decimal] = None # số tiền shipper phải thu hộ
    insurance_value: Optional[Decimal] = None


class GhnShipmentOut(BaseModel):
    id: int
    order_id: int
    ghn_order_code: Optional[str] = None # mã vận đơn để khách theo dõi
    status: Optional[str] = None
    service_id: Optional[int] = None
    service_type_id: Optional[int] = None
    shipping_fee: Optional[Decimal] = None
    cod_amount: Optional[Decimal] = None
    insurance_value: Optional[Decimal] = None
    expected_delivery_time: Optional[str] = None
    leadtime: Optional[str] = None
    tracking_url: Optional[str] = None
    note: Optional[str] = None

    class Config:
        from_attributes = True
