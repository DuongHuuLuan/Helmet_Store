from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class DiscountBase(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    percent: Decimal
    start_at: datetime
    end_at: datetime


class DiscountCreate(DiscountBase):
    pass


class DiscountUpdate(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    percent: Optional[Decimal] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    status: Optional[str] = None


class DiscountOut(DiscountBase):
    id: int
    status: str
    can_delete: bool = True
    class Config: from_attributes = True

class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int

class DiscountPaginationOut(BaseModel):
    items: List[DiscountOut]
    meta: PaginationMeta
