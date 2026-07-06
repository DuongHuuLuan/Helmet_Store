from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from app.infrastructure.database.models.product import UnitEnum
from app.application.dto.category_dto import CategoryOut
from app.application.dto.image_url_dto import ImageUrlOut
from app.application.dto.product_detail_dto import ProductDetailCreate, ProductDetailOut


class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    unit: UnitEnum = UnitEnum.CHIEC
    category_id: int


class ImageUloadPayload(BaseModel):
    url: str
    public_id: str
    color_id: Optional[int] = None


class ProductCreate(ProductBase):
    images: List[ImageUloadPayload] = []
    product_details: List[ProductDetailCreate] = []


class ProductQuantityOut(BaseModel):
    product_id: int
    size_id: int
    color_id: int
    total_quantity: int


class ProductOut(ProductBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    category: CategoryOut
    product_images: List[ImageUrlOut] = []
    design_views: List[ImageUrlOut] = []
    product_details: List[ProductDetailOut] = []
    can_delete: bool = True
    delete_block_reason: Optional[str] = None

    class Config:
        from_attributes = True


class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class ProductPaginationOut(BaseModel):
    items: List[ProductOut]
    meta: PaginationMeta

    class Config:
        from_attributes = True
