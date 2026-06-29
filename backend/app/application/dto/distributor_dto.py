from pydantic import BaseModel, EmailStr
from typing import List, Optional
from app.infrastructure.database.models import *

class DistributorBase(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    address: Optional[str]= None

class DistributorCreate(DistributorBase):
    pass

class DistributorOut(DistributorBase):
    id: int
    can_delete: bool = True

    class Config:
        from_attributes = True


class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class DistributorPaginationOut(BaseModel):
    items: List[DistributorOut]
    meta: PaginationMeta

