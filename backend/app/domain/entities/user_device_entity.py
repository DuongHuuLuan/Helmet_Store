from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class UserDeviceEntity:
    id: int
    user_id: int
    platform: str
    push_token: str
    device_id: Optional[str] = None
    is_active: bool = True
    last_seen_at: Optional[datetime] = None
    created_at: datetime = None
    updated_at: Optional[datetime] = None
