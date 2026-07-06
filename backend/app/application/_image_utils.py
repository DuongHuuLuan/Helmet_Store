from typing import List, Optional


def _pick_primary_from_bucket(images: list) -> Optional[object]:
    if not images:
        return None
    front = next(
        (img for img in images if str(getattr(img, "view_image_key", "") or "").strip() == "front-left"),
        None,
    )
    if front:
        return front
    generic = next(
        (img for img in images if not str(getattr(img, "view_image_key", "") or "").strip()),
        None,
    )
    return generic or images[0]


def pick_primary_image(images: list, color_id: Optional[int] = None) -> Optional[object]:
    items = list(images or [])
    if not items:
        return None
    by_color = [img for img in items if getattr(img, "color_id", None) == color_id]
    if by_color:
        return _pick_primary_from_bucket(by_color)
    commons = [img for img in items if getattr(img, "color_id", None) is None]
    if commons:
        return _pick_primary_from_bucket(commons)
    return _pick_primary_from_bucket(items)
