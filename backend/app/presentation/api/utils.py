from datetime import datetime
from typing import Dict, List, Optional

import cloudinary.uploader
from fastapi import UploadFile

from app.infrastructure.database.models.order import OrderStatus
from app.infrastructure.database.models.receipt import ReceiptStatus

def is_upload_file(value) -> bool:
    return hasattr(value, "file") and hasattr(value, "filename")


def parse_int(value) -> Optional[int]:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def parse_int_list(values) -> List[int]:
    result = []
    for value in values or []:
        parsed = parse_int(value)
        if parsed is not None:
            result.append(parsed)
    return result


def normalize_view_image_key(value) -> Optional[str]:
    if value is None:
        return None
    if is_upload_file(value):
        return None
    normalized = str(value).strip()
    return normalized or None


def extract_uploads(values) -> List[UploadFile]:
    return [v for v in (values or []) if is_upload_file(v)]


def extract_replace_images_map(form) -> Dict[int, UploadFile]:
    replace_map = {}
    for key, value in form.items():
        if not is_upload_file(value):
            continue
        if not key.startswith("replace_images[") or not key.endswith("]"):
            continue
        image_id = parse_int(key[len("replace_images[") : -1])
        if image_id is not None:
            replace_map[image_id] = value
    return replace_map


def extract_view_image_key_map(form) -> Dict[int, Optional[str]]:
    view_key_map = {}
    for key, value in form.items():
        if key.startswith("view_image_keys[") and key.endswith("]"):
            image_id = parse_int(key[len("view_image_keys[") : -1])
            if image_id is not None:
                view_key_map[image_id] = normalize_view_image_key(value)
    return view_key_map


def upload_images_to_cloudinary(
    files: List[UploadFile],
    color_ids: List[int] = None,
    view_image_keys: List[Optional[str]] = None,
):
    uploaded = []
    color_ids = color_ids or []
    view_image_keys = view_image_keys or []
    for idx, f in enumerate(files):
        result = cloudinary.uploader.upload(
            f.file,
            folder="helmet_shop/products",
        )
        color_id = color_ids[idx] if idx < len(color_ids) else None
        view_image_key = (
            normalize_view_image_key(view_image_keys[idx])
            if idx < len(view_image_keys)
            else None
        )
        uploaded.append(
            {
                "url": result["secure_url"],
                "public_id": result["public_id"],
                "color_id": color_id,
                "view_image_key": view_image_key,
            }
        )
    return uploaded
def format_dashboard_meta(timestamp: Optional[datetime]) -> str:
    if not timestamp:
        return "--"
    return timestamp.strftime("%H:%M %d/%m")


def get_status_tone(status: str) -> str:
    if status in [OrderStatus.CANCELLED, ReceiptStatus.CANCELLED]:
        return "alert"
    if status in [OrderStatus.PENDING, ReceiptStatus.PENDING]:
        return "warn"
    return "good"


def get_status_tag(status: str) -> str:
    status_map = {
        OrderStatus.PENDING: "Chờ xử lý",
        ReceiptStatus.PENDING: "Chờ xử lý",
        OrderStatus.CANCELLED: "Đã hủy",
        ReceiptStatus.CANCELLED: "Đã hủy",
        OrderStatus.SHIPPING: "Đang giao",
    }
    return status_map.get(status, "Hoàn tất")
