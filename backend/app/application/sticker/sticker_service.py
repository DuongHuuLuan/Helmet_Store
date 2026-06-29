import io
import os
import re

import cloudinary.uploader
from fastapi import HTTPException, status
from typing import Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.infrastructure.database.models import Sticker
from app.application.dto.sticker_dto import AiStickerGenerateIn
from app.infrastructure.external.openai.audio_service import OpenAIAudioService
from app.infrastructure.external.openai.image_service import OpenAIImageService


class StickerService:
    SUPPORTED_VOICE_AUDIO_EXTENSIONS = {
        ".mp3",
        ".mp4",
        ".mpeg",
        ".mpga",
        ".m4a",
        ".wav",
        ".webm",
    }

    @staticmethod
    def _validate_voice_audio(
        filename: str,
        content_type: Optional[str],
        audio_bytes: bytes,
    ) -> str:
        if not audio_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File audio không được để trống",
            )

        max_file_mb = max(int(settings.AI_STICKER_VOICE_MAX_FILE_MB or 0), 1)
        max_bytes = max_file_mb * 1024 * 1024
        if len(audio_bytes) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File audio vượt quá giới hạn {max_file_mb}MB",
            )

        normalized_filename = (filename or "").strip() or "ai-sticker-voice.m4a"
        extension = os.path.splitext(normalized_filename)[1].lower()
        normalized_content_type = (content_type or "").strip().lower()
        if extension and extension not in StickerService.SUPPORTED_VOICE_AUDIO_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Định dạng audio chưa được hỗ trợ",
            )
        if not extension and normalized_content_type and not normalized_content_type.startswith("audio/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File gửi lên không phải audio hợp lệ",
            )
        return normalized_filename

    @staticmethod
    def transcribe_voice_prompt(
        filename: str,
        content_type: Optional[str],
        audio_bytes: bytes,
    ) -> str:
        normalized_filename = StickerService._validate_voice_audio(
            filename=filename,
            content_type=content_type,
            audio_bytes=audio_bytes,
        )
        prompt = OpenAIAudioService.transcribe_audio(
            audio_bytes=audio_bytes,
            filename=normalized_filename,
            content_type=content_type,
        )
        normalized_prompt = re.sub(r"\s+", " ", prompt).strip()
        if len(normalized_prompt) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không nghe rõ mô tả sticker, Vui lòng thử lại",
            )
        return normalized_prompt[:500]

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
        upload_stream.name = f"{StickerService._normalize_public_id(name)}.png"
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
    def generate_ai_sticker(
        db: Session,
        user_id: int,
        sticker_in: AiStickerGenerateIn,
    ) -> Sticker:
        prompt = (sticker_in.prompt or "").strip()
        if not prompt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Prompt không được để trống",
            )

        sticker_name = StickerService._normalize_generated_name(sticker_in.name, prompt)
        ai_prompt = StickerService._build_ai_prompt(sticker_in)
        generated = OpenAIImageService.generate_sticker(
            prompt=ai_prompt,
            remove_background=sticker_in.remove_background,
        )
        upload_result = StickerService._upload_generated_image(
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

        sticker = Sticker(
            owner_user_id=user_id,
            name=sticker_name,
            image_url=image_url,
            public_id=public_id,
            category="AI Generated",
            is_ai_generated=True,
            has_transparent_background=generated.has_transparent_background,
        )
        db.add(sticker)

        try:
            db.commit()
        except Exception as exc:
            db.rollback()
            if public_id:
                cloudinary.uploader.destroy(public_id)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể lưu sticker AI vào hệ thống",
            ) from exc

        db.refresh(sticker)
        return sticker

    @staticmethod
    def _normalize_public_id(name: str) -> str:
        safe = re.sub(r"[^a-zA-Z0-9_-]", "_", name.strip())
        return safe[:120] or "sticker"

    @staticmethod
    def _normalize_generated_name(name: Optional[str], prompt: str) -> str:
        if name and name.strip():
            return name.strip()[:100]
        return (prompt.strip()[:80] or "ai-sticker").replace(" ", "_")
