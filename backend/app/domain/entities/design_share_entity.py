from typing import Optional
from datetime import datetime


class DesignShareEntity:
    def __init__(self, id: int, design_id: int, share_token: str,
                 public_url: str,
                 created_at: Optional[datetime] = None,
                 expires_at: Optional[datetime] = None):
        self.id = id
        self.design_id = design_id
        self.share_token = share_token
        self.public_url = public_url
        self.created_at = created_at
        self.expires_at = expires_at
