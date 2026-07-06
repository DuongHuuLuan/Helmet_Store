from typing import Any, Optional


class ProductionSnapshotService:
    DEFAULT_CANVAS_WIDTH_PX = 1080.0
    DEFAULT_CANVAS_HEIGHT_PX = 1000.0
    DEFAULT_PRINTABLE_WIDTH_MM = 240.0
    DEFAULT_PRINTABLE_HEIGHT_MM = round(
        DEFAULT_PRINTABLE_WIDTH_MM
        * (DEFAULT_CANVAS_HEIGHT_PX / DEFAULT_CANVAS_WIDTH_PX),
        2,
    )
    BASE_LAYER_RATIO = 0.24
    MIN_LAYER_PX = 34.0
    MAX_LAYER_RATIO = 0.52
    _VIEW_IMAGE_ORDER = {
        "front": 0,
        "front_right": 1,
        "right": 2,
        "back": 3,
        "left": 4,
        "front_left": 5,
    }

    @staticmethod
    def _normalize_view_image_key(value: Any) -> Optional[str]:
        key = str(value or "").strip().lower()
        return key or None

    @staticmethod
    def _view_order(view_image_key: Any) -> int:
        key = ProductionSnapshotService._normalize_view_image_key(view_image_key)
        if key is None:
            return len(ProductionSnapshotService._VIEW_IMAGE_ORDER) + 1
        return ProductionSnapshotService._VIEW_IMAGE_ORDER.get(
            key,
            len(ProductionSnapshotService._VIEW_IMAGE_ORDER),
        )

    @staticmethod
    def _view_label(view_image_key: Any) -> Optional[str]:
        mapping = {
            "front": "Mặt trước",
            "front_right": "Trước phải",
            "right": "Bên phải",
            "back": "Mặt sau",
            "left": "Bên trái",
            "front_left": "Trước trái",
        }
        key = ProductionSnapshotService._normalize_view_image_key(view_image_key)
        if key is None:
            return None
        return mapping.get(key)

    @staticmethod
    def _serialize_layer(layer: Any) -> dict[str, Any]:
        return {
            "id": getattr(layer, "id", None),
            "sticker_id": getattr(layer, "sticker_id", None),
            "image_url": getattr(layer, "image_url", ""),
            "x": float(getattr(layer, "x", 0) or 0),
            "y": float(getattr(layer, "y", 0) or 0),
            "scale": float(getattr(layer, "scale", 1) or 1),
            "rotation": float(getattr(layer, "rotation", 0) or 0),
            "z_index": int(getattr(layer, "z_index", 0) or 0),
            "view_image_key": getattr(layer, "view_image_key", None),
            "tint_color_value": getattr(layer, "tint_color_value", None),
            "crop_left": float(getattr(layer, "crop_left", 0) or 0),
            "crop_top": float(getattr(layer, "crop_top", 0) or 0),
            "crop_right": float(getattr(layer, "crop_right", 1) or 1),
            "crop_bottom": float(getattr(layer, "crop_bottom", 1) or 1),
        }

    @staticmethod
    def _resolve_view_images_from_product(
        product_images: Optional[list[Any]],
        color_id: Optional[int] = None,
    ) -> Optional[list[dict[str, Any]]]:
        if not product_images:
            return None
        results = []
        for img in product_images:
            img_color_id = getattr(img, "color_id", None) or (
                img.get("color_id") if isinstance(img, dict) else None
            )
            if color_id is not None and img_color_id != color_id:
                continue
            view_key = getattr(img, "view_image_key", None) or (
                img.get("view_image_key") if isinstance(img, dict) else None
            )
            image_url = getattr(img, "image_url", None) or (
                img.get("image_url") if isinstance(img, dict) else None
            )
            results.append({
                "view_image_key": view_key,
                "image_url": image_url,
                "view_label": ProductionSnapshotService._view_label(view_key),
                "view_order": ProductionSnapshotService._view_order(view_key),
            })
        results.sort(key=lambda x: x["view_order"])
        return results if results else None

    @staticmethod
    def build_design_snapshot(
        design: Optional[Any],
        product_images: Optional[list[Any]] = None,
        color_id: Optional[int] = None,
    ) -> Optional[dict[str, Any]]:
        if not design:
            return None

        layers = sorted(
            list(getattr(design, "layers", []) or []),
            key=lambda item: item.z_index,
        )
        snapshot = {
            "design_id": design.id,
            "name": design.name,
            "base_image_url": design.base_image_url,
            "preview_image_url": design.preview_image_url,
            "is_shared": design.is_shared,
            "canvas_width_px": ProductionSnapshotService.DEFAULT_CANVAS_WIDTH_PX,
            "canvas_height_px": ProductionSnapshotService.DEFAULT_CANVAS_HEIGHT_PX,
            "printable_width_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_WIDTH_MM,
            "printable_height_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_HEIGHT_MM,
            "layers": [
                ProductionSnapshotService._serialize_layer(layer) for layer in layers
            ],
        }

        view_images = ProductionSnapshotService._resolve_view_images_from_product(
            product_images,
            color_id,
        )
        if view_images:
            snapshot["view_images"] = view_images
        return snapshot

    @staticmethod
    def build_order_detail_payload(order_detail: Any) -> dict[str, Any]:
        product_detail = getattr(order_detail, "product_detail", None)
        product = getattr(product_detail, "product", None) if product_detail else None
        return {
            "order_detail_id": getattr(order_detail, "id", 0),
            "product_detail_id": getattr(order_detail, "product_detail_id", None),
            "quantity": int(getattr(order_detail, "quantity", 0) or 0),
            "price": float(getattr(order_detail, "price", 0) or 0),
            "design_id": getattr(order_detail, "design_id", None),
            "design_snapshot_json": getattr(order_detail, "design_snapshot_json", None),
            "product_name": getattr(product, "name", None) if product else None,
        }

    @staticmethod
    def build_order_production_payload(order: Any) -> dict[str, Any]:
        items = [
            ProductionSnapshotService.build_order_detail_payload(order_detail)
            for order_detail in getattr(order, "order_details", []) or []
        ]

        payment_status = getattr(order, "payment_status", None)
        refund_support_status = getattr(order, "refund_support_status", None)
        status = getattr(order, "status", None)

        return {
            "order_id": getattr(order, "id", 0),
            "status": getattr(status, "value", status),
            "payment_status": getattr(payment_status, "value", payment_status),
            "refund_support_status": getattr(
                refund_support_status,
                "value",
                refund_support_status,
            ),
            "rejection_reason": getattr(order, "rejection_reason", None),
            "items": items,
        }
