from typing import Optional
from datetime import datetime


class EvaluateEntity:
    def __init__(self, id: int, order_id: int, user_id: int,
                 rate: int,
                 content: Optional[str] = None,
                 image: Optional[str] = None,
                 admin_id: Optional[int] = None,
                 admin_reply: Optional[str] = None,
                 admin_replied_at: Optional[datetime] = None,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None):
        self.id = id
        self.order_id = order_id
        self.user_id = user_id
        self.rate = rate
        self.content = content
        self.image = image
        self.admin_id = admin_id
        self.admin_reply = admin_reply
        self.admin_replied_at = admin_replied_at
        self.created_at = created_at
        self.updated_at = updated_at


class EvaluateImageEntity:
    def __init__(self, id: int, evaluate_id: int, image_url: str,
                 public_id: Optional[str] = None,
                 sort_order: Optional[int] = None,
                 created_at: Optional[datetime] = None):
        self.id = id
        self.evaluate_id = evaluate_id
        self.image_url = image_url
        self.public_id = public_id
        self.sort_order = sort_order
        self.created_at = created_at
