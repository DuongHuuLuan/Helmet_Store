import re
import uuid
from typing import Optional

from fastapi import HTTPException, status

from app.domain.repositories.sticker_repository import StickerRepository
from app.application.dto.sticker_dto import StickerUpdate


class UpdateStickerUseCase:
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

    def execute(self, sticker_id: int, sticker_in: StickerUpdate) -> dict:
        entity = self.repo.get_by_id(sticker_id)
        if not entity or entity.owner_user_id is not None:
            raise HTTPException(status_code=404, detail="System sticker not found")

        data = {
            "name": sticker_in.name.strip(),
            "image_url": sticker_in.image_url.strip(),
            "category": (sticker_in.category or "General").strip() or "General",
            "is_ai_generated": bool(sticker_in.is_ai_generated),
            "has_transparent_background": bool(sticker_in.has_transparent_background),
            "public_id": self._normalize_public_id(
                sticker_in.name,
                sticker_in.public_id or entity.public_id,
            ),
        }
        updated = self.repo.update(sticker_id, data)
        usage = self.repo.count_usage(sticker_id)

        return {
            "id": updated.id,
            "owner_user_id": None,
            "owner_username": None,
            "owner_email": None,
            "name": updated.name,
            "image_url": updated.image_url,
            "public_id": updated.public_id,
            "category": updated.category,
            "is_ai_generated": updated.is_ai_generated,
            "has_transparent_background": updated.has_transparent_background,
            "usage_count": usage,
            "can_edit": True,
            "can_delete": usage == 0,
            "created_at": updated.created_at,
            "updated_at": updated.updated_at,
        }
