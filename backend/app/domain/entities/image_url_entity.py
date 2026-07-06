from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class ImageUrlEntity:
    id: int
    product_id: int
    url: str
    public_id: str
    color_id: Optional[int] = None
    view_image_key: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
