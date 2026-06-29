from typing import Optional
from datetime import datetime


class DesignEntity:
    def __init__(self, id: int, user_id: int, product_id: int,
                 product_detail_id: Optional[int] = None,
                 name: str = "", base_image_url: str = "",
                 preview_image_url: Optional[str] = None,
                 is_shared: bool = False,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None):
        self.id = id
        self.user_id = user_id
        self.product_id = product_id
        self.product_detail_id = product_detail_id
        self.name = name
        self.base_image_url = base_image_url
        self.preview_image_url = preview_image_url
        self.is_shared = is_shared
        self.created_at = created_at
        self.updated_at = updated_at
