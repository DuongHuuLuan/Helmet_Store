from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from decimal import Decimal

from app.application.dto.product_dto import ProductOut
from app.application.dto.product_detail_dto import ColorOut, SizeOut
from app.application.dto.distributor_dto import DistributorOut
from app.application.dto.warehouse_dto import WarehouseOut


class ReceiptDetailBase(BaseModel):
    product_id: int
    color_id: Optional[int] = None
    size_id: Optional[int] = None
    quantity: int
    purchase_price: Decimal


class ReceiptDetailCreate(ReceiptDetailBase):
    pass


class ReceiptDetailItemOut(ReceiptDetailBase):
    id: int
    product: Optional[ProductOut] = None
    color: Optional[ColorOut] = None
    size: Optional[SizeOut] = None

    class Config:
        from_attributes = True


class ReceiptCreate(BaseModel):
    warehouse_id: int
    distributor_id: int
    details: List[ReceiptDetailCreate]


class ReceiptOut(BaseModel):
    id: int
    warehouse_id: int
    distributor_id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    warehouse: Optional[WarehouseOut] = None
    distributor: Optional[DistributorOut] = None
    details: List[ReceiptDetailItemOut] = []

    class Config:
        from_attributes = True


class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class ReceiptListItemOut(BaseModel):
    id: int
    status: str
    created_at: datetime
    warehouse: Optional[WarehouseOut] = None
    distributor: Optional[DistributorOut] = None
    items_count: int = 0

    class Config:
        from_attributes = True


class ReceiptPaginationOut(BaseModel):
    items: List[ReceiptListItemOut]
    meta: PaginationMeta

    class Config:
        from_attributes = True
