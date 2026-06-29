import re
import uuid
from typing import Optional

from app.domain.repositories.sticker_repository import StickerRepository
from app.application.dto.sticker_dto import StickerCreate


class CreateStickerUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    @staticmethod
    def _normalize_public_id(name: str, public_id: Optional[str] = None) -> str:
        normalized = (public_id or "").strip()
        if normalized:
            return normalized
        slug = re.sub(r"[^a-z0-9]+", "-", (name or "").strip().lower()).strip("-")
        if not slug:
            slug = "system-sticker"
        return f"{slug}-{uuid.uuid4().hex[:10]}"

    def execute(self, sticker_in: StickerCreate) -> dict:
        data = {
            "owner_user_id": None,
            "name": sticker_in.name.strip(),
            "image_url": sticker_in.image_url.strip(),
            "public_id": self._normalize_public_id(sticker_in.name, sticker_in.public_id),
            "category": (sticker_in.category or "General").strip() or "General",
            "is_ai_generated": bool(sticker_in.is_ai_generated),
            "has_transparent_background": bool(sticker_in.has_transparent_background),
        }
        entity = self.repo.create(data)
        return {
            "id": entity.id,
            "owner_user_id": None,
            "owner_username": None,
            "owner_email": None,
            "name": entity.name,
            "image_url": entity.image_url,
            "public_id": entity.public_id,
            "category": entity.category,
            "is_ai_generated": entity.is_ai_generated,
            "has_transparent_background": entity.has_transparent_background,
            "usage_count": 0,
            "can_edit": True,
            "can_delete": True,
            "created_at": entity.created_at,
            "updated_at": entity.updated_at,
        }
