import io
import os
import re

import cloudinary.uploader
from fastapi import HTTPException, status

from app.core.config import settings
from app.domain.repositories.sticker_repository import StickerRepository
from app.application.dto.sticker_dto import AiStickerGenerateIn
from app.infrastructure.external.openai.image_service import OpenAIImageService


class GenerateAiStickerUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, user_id: int, sticker_in: AiStickerGenerateIn):
        prompt = (sticker_in.prompt or "").strip()
        if not prompt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Prompt không được để trống",
            )

        sticker_name = self._normalize_generated_name(sticker_in.name, prompt)
        ai_prompt = self._build_ai_prompt(sticker_in)
        generated = OpenAIImageService.generate_sticker(
            prompt=ai_prompt,
            remove_background=sticker_in.remove_background,
        )
        upload_result = self._upload_generated_image(
            image_bytes=generated.image_bytes,
            name=sticker_name,
        )
        image_url = upload_result.get("secure_url")
        public_id = upload_result.get("public_id")
        if not image_url or not public_id:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Cloudinary không trả về thông tin hợp lệ",
            )

        data = {
            "owner_user_id": user_id,
            "name": sticker_name,
            "image_url": image_url,
            "public_id": public_id,
            "category": "AI Generated",
            "is_ai_generated": True,
            "has_transparent_background": generated.has_transparent_background,
        }

        try:
            entity = self.repo.create(data)
        except Exception as exc:
            if public_id:
                cloudinary.uploader.destroy(public_id)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể lưu sticker AI vào hệ thống",
            ) from exc

        return {
            "id": entity.id,
            "name": entity.name,
            "image_url": entity.image_url,
            "category": entity.category,
            "is_ai_generated": entity.is_ai_generated,
            "has_transparent_background": entity.has_transparent_background,
        }

    @staticmethod
    def _build_ai_prompt(sticker_in: AiStickerGenerateIn) -> str:
        parts = [
            "Create one clean sticker illustration with a single centered subject.",
            "Use a bold outline, simple readable shapes, and strong contrast.",
            "Do not include any text, watermark, logo, frame, or extra objects.",
        ]

        if sticker_in.remove_background:
            parts.append("Use a transparent background.")
        else:
            parts.append("Keep the background minimal and unobtrusive.")

        if sticker_in.style and sticker_in.style.strip():
            parts.append(f"Visual style: {sticker_in.style.strip()}.")

        if sticker_in.dominant_color and sticker_in.dominant_color.strip():
            parts.append(f"Dominant color palette: {sticker_in.dominant_color.strip()}.")

        parts.append(f"Subject: {sticker_in.prompt.strip()}.")
        return " ".join(parts)

    @staticmethod
    def _upload_generated_image(image_bytes: bytes, name: str) -> dict:
        upload_stream = io.BytesIO(image_bytes)
        upload_stream.name = f"{GenerateAiStickerUseCase._normalize_public_id(name)}.png"
        try:
            return cloudinary.uploader.upload(
                upload_stream,
                folder=settings.AI_STICKER_CLOUDINARY_FOLDER,
                resource_type="image",
                format="png",
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Không thể tải ảnh sticker lên Cloudinary: {exc}",
            ) from exc

    @staticmethod
    def _normalize_public_id(name: str) -> str:
        safe = re.sub(r"[^a-zA-Z0-9_-]", "_", name.strip())
        return safe[:120] or "sticker"

    @staticmethod
    def _normalize_generated_name(name: str | None, prompt: str) -> str:
        if name and name.strip():
            return name.strip()[:100]
        return (prompt.strip()[:80] or "ai-sticker").replace(" ", "_")
