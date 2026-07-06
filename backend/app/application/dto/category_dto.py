from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class CategoryBase(BaseModel):
    name: str

class CategoryCreate(CategoryBase):
    pass

class CategoryOut(CategoryBase):
    id: int
    products_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True

class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class CategoryPaginationOut(BaseModel):
    items: List[CategoryOut]
    meta: PaginationMeta

    class Config:
        from_attributes = True