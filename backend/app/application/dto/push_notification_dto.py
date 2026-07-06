from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.infrastructure.database.models.push_notification import DevicePlatform


class UserDeviceUpsertIn(BaseModel):
    platform: DevicePlatform
    push_token: str = Field(..., min_length=20, max_length=512)
    device_id: Optional[str] = Field(default=None, max_length=128)


class UserDeviceOut(BaseModel):
    id: int
    user_id: int
    platform: DevicePlatform
    device_id: Optional[str] = None
    push_token: str
    is_active: bool
    last_seen_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
