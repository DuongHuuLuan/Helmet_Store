from pydantic import BaseModel, HttpUrl
from datetime import datetime
from typing import Optional, List

class ImageURLBase(BaseModel):
    url: str
    public_id: str
    color_id: Optional[int] = None
    view_image_key: Optional[str] = None


class ImageURLCreate(ImageURLBase):
    product_id: int
    url: str
    public_id: str

class ImageUrlOut(ImageURLBase):
    id: int
    product_id: int
    url: str
    public_id: str
    color_id: Optional[int]
    view_image_key: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
