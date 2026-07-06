from typing import Optional
from datetime import datetime


class StickerEntity:
    def __init__(self, id: int,
                 owner_user_id: Optional[int] = None,
                 name: str = "", image_url: str = "",
                 public_id: str = "", category: str = "General",
                 is_ai_generated: bool = False,
                 has_transparent_background: bool = False,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None):
        self.id = id
        self.owner_user_id = owner_user_id
        self.name = name
        self.image_url = image_url
        self.public_id = public_id
        self.category = category
        self.is_ai_generated = is_ai_generated
        self.has_transparent_background = has_transparent_background
        self.created_at = created_at
        self.updated_at = updated_at
