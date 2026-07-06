import base64
import binascii
from dataclasses import dataclass

import httpx
from fastapi import HTTPException, status

from app.core.config import settings


@dataclass
class GeneratedImageResult:
    image_bytes: bytes
    mime_type: str
    has_transparent_background: bool


class OpenAIImageService:
    @staticmethod
    def _headers() -> dict:
        if not settings.OPENAI_API_KEY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OPENAI_API_KEY chưa được cấu hình",
            )
        return {
            "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
            "Content-Type": "application/json",
        }

    @staticmethod
    def _model_name() -> str:
        model_name = (settings.OPENAI_IMAGE_MODEL or "").strip()
        if not model_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OPENAI_IMAGE_MODEL chưa được cấu hình",
            )
        return model_name

    @staticmethod
    def _is_gpt_image_model(model_name: str) -> bool:
        return model_name.startswith("gpt-image-") or model_name == "gpt-image-1"

    @staticmethod
    def _normalized_quality(model_name: str) -> str:
        quality = (settings.OPENAI_IMAGE_QUALITY or "").strip().lower()
        if not quality:
            return "medium" if OpenAIImageService._is_gpt_image_model(model_name) else "standard"

        if OpenAIImageService._is_gpt_image_model(model_name):
            legacy_map = {
                "standard": "medium",
                "hd": "high",
            }
            return legacy_map.get(quality, quality)

        return quality

    @staticmethod
    def _build_payload(prompt: str, remove_background: bool) -> dict:
        model_name = OpenAIImageService._model_name()
        payload = {
            "model": model_name,
            "prompt": prompt,
            "size": settings.OPENAI_IMAGE_SIZE,
            "quality": OpenAIImageService._normalized_quality(model_name),
            "n": 1,
        }
        if OpenAIImageService._is_gpt_image_model(model_name):
            payload["output_format"] = "png"
        else:
            payload["response_format"] = "b64_json"

        if remove_background and OpenAIImageService._is_gpt_image_model(model_name):
            payload["background"] = "transparent"
        return payload

    @staticmethod
    def _extract_error_message(response: httpx.Response) -> str:
        try:
            data = response.json()
        except ValueError:
            return response.text or "OpenAI image generation failed"

        error = data.get("error")
        if isinstance(error, dict):
            return error.get("message") or "OpenAI image generation failed"
        return data.get("message") or "OpenAI image generation failed"

    @staticmethod
    def generate_sticker(prompt: str, remove_background: bool) -> GeneratedImageResult:
        url = f"{settings.OPENAI_BASE_URL.rstrip('/')}/images/generations"
        payload = OpenAIImageService._build_payload(prompt, remove_background)

        try:
            response = httpx.post(
                url,
                json=payload,
                headers=OpenAIImageService._headers(),
                timeout=settings.OPENAI_IMAGE_TIMEOUT_SECONDS,
            )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Không thể kết nối OpenAI: {exc}",
            ) from exc

        if response.status_code >= 400:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=OpenAIImageService._extract_error_message(response),
            )

        try:
            data = response.json()
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI trả về dữ liệu không hợp lệ",
            ) from exc

        image_items = data.get("data") or []
        # lấy ảnh đầu tiên trong danh sách image_items
        first_image = image_items[0] if image_items else None

        # giải mã hình ảnh từ trường b64_json về dạng Binary (Bytes)
        image_base64 = first_image.get("b64_json")

        try:
            image_bytes = base64.b64decode(image_base64)
        except (binascii.Error, ValueError) as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Không giải mã được ảnh từ OpenAI",
            ) from exc

        background_mode = data.get("background") or first_image.get("background")
        has_transparent_background = background_mode == "transparent" or remove_background

        return GeneratedImageResult(
            image_bytes=image_bytes,
            mime_type="image/png",
            has_transparent_background=has_transparent_background,
        )
