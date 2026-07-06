import json
from typing import Any, Dict, List

import httpx
from fastapi import HTTPException, status

from app.core.config import settings


class OpenAIChatService:
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
    def _model_names() -> List[str]:
        candidates: List[str] = []
        primary_model = (settings.OPENAI_CHAT_MODEL or "").strip()
        fallback_model = (settings.OPENAI_CHAT_FALLBACK_MODEL or "").strip()

        if primary_model:
            candidates.append(primary_model)
        if fallback_model and fallback_model not in candidates:
            candidates.append(fallback_model)

        if not candidates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OPENAI_CHAT_MODEL chưa được cấu hình",
            )
        return candidates

    @staticmethod
    def _extract_error_message(response: httpx.Response) -> str:
        try:
            data = response.json()
        except ValueError:
            return response.text or "OpenAI chat failed"

        error = data.get("error")
        if isinstance(error, dict):
            return error.get("message") or "OpenAI chat failed"
        return data.get("message") or "OpenAI chat failed"

    @staticmethod
    def _response_schema() -> Dict[str, Any]:
        return {
            "name": "chatbot_product_reply",
            "strict": True,
            "schema": {
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string",
                    },
                    "matched_product_ids": {
                        "type": "array",
                        "items": {
                            "type": "integer",
                        },
                    },
                    "follow_up_suggestions": {
                        "type": "array",
                        "items": {
                            "type": "string",
                        },
                    },
                },
                "required": [
                    "message",
                    "matched_product_ids",
                    "follow_up_suggestions",
                ],
                "additionalProperties": False,
            },
        }

    @staticmethod
    def _build_request_payload(
        model_name: str,
        user_message: str,
        recent_messages: List[Dict[str, str]],
        candidate_products: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        instructions = (
            "Bạn là chatbot tư vấn sản phẩm cho cửa hàng nón bảo hiểm. "
            "Chỉ được tư vấn dựa trên dữ liệu JSON được cung cấp. "
            "Không bịa giá, tồn kho, màu, size, chính sách hoặc sản phẩm ngoài danh sách candidate_products. "
            "Trả về JSON đúng schema. "
            "Trường matched_product_ids chỉ được chứa product_id có trong candidate_products. "
            "Nếu không có sản phẩm phù hợp, để matched_product_ids rỗng và trả lời ngắn gọn, lịch sự."
        )
        prompt_payload = {
            "user_message": user_message,
            "recent_messages": recent_messages,
            "candidate_products": candidate_products,
        }
        return {
            "model": model_name,
            "instructions": instructions,
            "input": json.dumps(prompt_payload, ensure_ascii=False),
            "text": {
                "format": {
                    "type": "json_schema",
                    **OpenAIChatService._response_schema(),
                }
            },
            "store": False,
        }

    @staticmethod
    def _extract_output_text(data: Dict[str, Any]) -> str:
        output_items = data.get("output")
        if not isinstance(output_items, list):
            return ""

        text_parts: List[str] = []
        for item in output_items:
            if not isinstance(item, dict):
                continue
            content_items = item.get("content")
            if not isinstance(content_items, list):
                continue
            for content_item in content_items:
                if not isinstance(content_item, dict):
                    continue
                if content_item.get("type") != "output_text":
                    continue
                text_value = content_item.get("text")
                if isinstance(text_value, str) and text_value.strip():
                    text_parts.append(text_value)
        return "".join(text_parts).strip()

    @staticmethod
    def _parse_reply_payload(data: Dict[str, Any]) -> Dict[str, Any]:
        raw_text = OpenAIChatService._extract_output_text(data)
        if not raw_text:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI không trả về nội dung chatbot hợp lệ",
            )

        try:
            parsed = json.loads(raw_text)
        except (TypeError, ValueError, json.JSONDecodeError) as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Không đọc được phản hồi chatbot từ OpenAI",
            ) from exc

        if not isinstance(parsed, dict):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI trả về dữ liệu chatbot không hợp lệ",
            )

        matched_product_ids = parsed.get("matched_product_ids")
        if not isinstance(matched_product_ids, list):
            matched_product_ids = []

        follow_up_suggestions = parsed.get("follow_up_suggestions")
        if not isinstance(follow_up_suggestions, list):
            follow_up_suggestions = []

        return {
            "message": str(parsed.get("message") or "").strip(),
            "matched_product_ids": [
                int(product_id)
                for product_id in matched_product_ids
                if isinstance(product_id, int)
            ],
            "follow_up_suggestions": [
                str(item).strip()
                for item in follow_up_suggestions
                if str(item).strip()
            ],
        }

    @staticmethod
    def generate_product_reply(
        user_message: str,
        recent_messages: List[Dict[str, str]],
        candidate_products: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        url = f"{settings.OPENAI_BASE_URL.rstrip('/')}/responses"
        errors: List[str] = []

        for model_name in OpenAIChatService._model_names():
            try:
                response = httpx.post(
                    url,
                    json=OpenAIChatService._build_request_payload(
                        model_name=model_name,
                        user_message=user_message,
                        recent_messages=recent_messages,
                        candidate_products=candidate_products,
                    ),
                    headers=OpenAIChatService._headers(),
                    timeout=settings.OPENAI_CHAT_TIMEOUT_SECONDS,
                )
            except httpx.HTTPError as exc:
                errors.append(f"{model_name}: {exc}")
                continue

            if response.status_code >= 400:
                errors.append(f"{model_name}: {OpenAIChatService._extract_error_message(response)}")
                continue

            try:
                data = response.json()
            except ValueError:
                errors.append(f"{model_name}: OpenAI trả về dữ liệu không hợp lệ")
                continue

            try:
                return OpenAIChatService._parse_reply_payload(data)
            except HTTPException as exc:
                errors.append(f"{model_name}: {exc.detail}")
                continue

        error_detail = errors[-1] if errors else "Không thể tạo phản hồi chatbot từ OpenAI"
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=error_detail,
        )
