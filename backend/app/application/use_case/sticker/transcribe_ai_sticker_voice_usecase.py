import os
import re
from typing import Optional

from fastapi import HTTPException, status

from app.core.config import settings
from app.infrastructure.external.openai.audio_service import OpenAIAudioService


class TranscribeAiStickerVoiceUseCase:
    SUPPORTED_VOICE_AUDIO_EXTENSIONS = {
        ".mp3",
        ".mp4",
        ".mpeg",
        ".mpga",
        ".m4a",
        ".wav",
        ".webm",
    }

    def execute(self, audio_bytes: bytes, filename: str, content_type: Optional[str]) -> str:
        normalized_filename = self._validate_voice_audio(
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
        if extension and extension not in TranscribeAiStickerVoiceUseCase.SUPPORTED_VOICE_AUDIO_EXTENSIONS:
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
