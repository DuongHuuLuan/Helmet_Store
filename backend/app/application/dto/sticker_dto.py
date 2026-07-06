from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class StickerBase(BaseModel):
    name: str
    image_url: str
    category: str = "General"
    is_ai_generated: bool = False
    has_transparent_background: bool = False


class StickerCreate(StickerBase):
    public_id: Optional[str] = None


class StickerUpdate(BaseModel):
    name: str
    image_url: str
    category: str = "General"
    is_ai_generated: bool = False
    has_transparent_background: bool = False
    public_id: Optional[str] = None


class StickerOut(StickerBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class StickerListOut(BaseModel):
    items: List[StickerOut]


class StickerAdminOut(StickerOut):
    owner_user_id: Optional[int] = None
    owner_username: Optional[str] = None
    owner_email: Optional[str] = None
    public_id: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    usage_count: int = 0
    can_edit: bool = True
    can_delete: bool = True

    model_config = ConfigDict(from_attributes=True)


class StickerPaginationMeta(BaseModel):
    total: int = 0
    current_page: int = 1
    per_page: int = 0
    last_page: int = 1


class StickerAdminPaginationOut(BaseModel):
    items: List[StickerAdminOut] = Field(default_factory=list)
    meta: StickerPaginationMeta = Field(default_factory=StickerPaginationMeta)


class AiStickerGenerateIn(BaseModel):
    prompt: str
    name: Optional[str] = None
    style: Optional[str] = None
    dominant_color: Optional[str] = None
    remove_background: bool = True


class AiStickerTranscriptionOut(BaseModel):
    prompt: str


class RemoveBackgroundIn(BaseModel):
    image_url: str


class RemoveBackgroundOut(BaseModel):
    image_url: str
