import os
from typing import Optional

import httpx
from fastapi import HTTPException, status

from app.core.config import settings


class OpenAIAudioService:
    @staticmethod
    def _headers() -> dict:
        if not settings.OPENAI_API_KEY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OPENAI_API_KEY chưa được cấu hình",
            )
        return {
            "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
        }

    @staticmethod
    def _model_name() -> str:
        model_name = (settings.OPENAI_TRANSCRIPTION_MODEL or "").strip()
        if not model_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OPENAI_TRANSCRIPTION_MODEL chưa được cấu hình",
            )
        return model_name

    @staticmethod
    def _extract_error_message(response: httpx.Response) -> str:
        try:
            data = response.json()
        except ValueError:
            return response.text or "OpenAI transcription failed"

        error = data.get("error")
        if isinstance(error, dict):
            return error.get("message") or "OpenAI transcription failed"
        return data.get("message") or "OpenAI transcription failed"

    @staticmethod
    def transcribe_audio(
        audio_bytes: bytes,
        filename: str,
        content_type: Optional[str] = None,
    ) -> str:
        if not audio_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File audio không được để trống",
            )

        url = f"{settings.OPENAI_BASE_URL.rstrip('/')}/audio/transcriptions"
        normalized_filename = (filename or "").strip() or "ai-sticker-voice.m4a"
        normalized_type = (content_type or "").strip() or "application/octet-stream"
        data = {
            "model": OpenAIAudioService._model_name(),
        }
        normalized_language = (settings.OPENAI_TRANSCRIPTION_LANGUAGE or "").strip()
        if normalized_language:
            data["language"] = normalized_language

        try:
            response = httpx.post(
                url,
                headers=OpenAIAudioService._headers(),
                data=data,
                files={
                    "file": (
                        os.path.basename(normalized_filename),
                        audio_bytes,
                        normalized_type,
                    )
                },
                timeout=settings.OPENAI_TRANSCRIPTION_TIMEOUT_SECONDS,
            )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Không thể kết nối OpenAI để nhận giọng nói: {exc}",
            ) from exc

        if response.status_code >= 400:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=OpenAIAudioService._extract_error_message(response),
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI trả về dữ liệu nhận giọng nói không hợp lệ",
            ) from exc

        prompt = (payload.get("text") or "").strip()
        if not prompt:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI không trả về nội dung giọng nói hợp lệ",
            )
        return prompt
