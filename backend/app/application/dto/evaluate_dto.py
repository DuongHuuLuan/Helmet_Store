from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class EvaluateCreate(BaseModel):
    rate: int = Field(..., ge=1, le=5, description="Số sao từ 1 đến 5")
    content: Optional[str] = None


class EvaluateReplyCreate(BaseModel):
    admin_reply: str = Field(..., min_length=1, max_length=2000)

class EvaluateImageOut(BaseModel):
    id: int
    image_url: str
    sort_order: Optional[int] = None

    class Config:
        from_attributes = True


class EvaluateOut(BaseModel):
    id: int
    order_id: int
    user_id: int
    admin_id: Optional[int] = None

    rate: int
    content: Optional[str] = None

    admin_reply: Optional[str] = None
    admin_replied_at: Optional[datetime] = None

    created_at: datetime
    updated_at: Optional[datetime] = None

    images: List[EvaluateImageOut] = Field(default_factory=list)
    
    class Config:
        from_attributes = True


class ProductEvaluateOut(EvaluateOut):
    evaluater_name: Optional[str] = None
    evaluater_name_masked: Optional[str] = None
    matched_variants: List[str] = Field(default_factory=list)
    has_images: bool = False


class EvaluateProductRateCount(BaseModel):
    star: int = Field(..., ge=1, le=5)
    count: int = Field(..., ge=0)


class EvaluateProductSummaryOut(BaseModel):
    product_id: int
    average_rate: float = 0
    total_evaluates: int = 0
    total_with_images: int = 0
    summary_text: Optional[str] = None
    rate_counts: List[EvaluateProductRateCount] = Field(default_factory=list)


class EvaluatePaginationMeta(BaseModel):
    page: int
    per_page: int
    total: int
    total_pages: int


class EvaluatePaginationOut(BaseModel):
    items: List[EvaluateOut]
    meta: EvaluatePaginationMeta


class EvaluateProductPaginationOut(BaseModel):
    summary: EvaluateProductSummaryOut
    items: List[ProductEvaluateOut]
    meta: EvaluatePaginationMeta
