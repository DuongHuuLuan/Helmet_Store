from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional


@dataclass
class ProfileEntity:
    id: int
    user_id: int
    name: str
    phone: Optional[str] = None
    gender: Optional[str] = "male"
    birthday: Optional[date] = None
    avatar: Optional[str] = None
    avatar_public_id: Optional[str] = None
    created_at: datetime = None
    updated_at: Optional[datetime] = None
