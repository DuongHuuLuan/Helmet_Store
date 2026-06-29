from typing import Optional

from fastapi import HTTPException, status

from app.domain.repositories.design_repository import DesignRepository
from app.application.dto.design_dto import DesignCreate, DesignLayerIn


_ALLOWED_VIEW_IMAGE_KEYS = {
    "front", "front_right", "right", "back",
    "left", "front_left",
}


class CreateDesignUseCase:
    def __init__(self, design_repo: DesignRepository):
        self.design_repo = design_repo
        self._allowed_view_image_keys = _ALLOWED_VIEW_IMAGE_KEYS

    @staticmethod
    def _normalize_view_image_key(value: Optional[str]) -> Optional[str]:
        normalized = (value or "").strip().lower().replace(" ", "_")
        return normalized if normalized in _ALLOWED_VIEW_IMAGE_KEYS else None

    @staticmethod
    def _normalize_layers(layers: list[DesignLayerIn]):
        indexed = list(enumerate(layers))
        indexed.sort(key=lambda item: (item[1].z_index, item[0]))
        return indexed

    def execute(self, user_id: int, design_in: DesignCreate) -> dict:
        sticker_ids = [s.sticker_id for s in design_in.stickers]
        sticker_map = {}
        if sticker_ids:
            stickers, missing = self.design_repo.validate_stickers(sticker_ids, user_id)
            if missing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Sticker không hợp lệ hoặc bạn không có quyền sở hữu sticker này",
                )
            sticker_map = {s.id: s for s in stickers}

        design_data = {
            "product_id": design_in.product_id,
            "product_detail_id": design_in.product_detail_id,
            "name": design_in.name,
            "base_image_url": design_in.base_image_url,
        }

        layers_data = []
        for normalized_z_index, (_, layer_in) in enumerate(
            self._normalize_layers(design_in.stickers)
        ):
            sticker = sticker_map[layer_in.sticker_id]
            crop = layer_in.crop
            layers_data.append(
                {
                    "sticker_id": layer_in.sticker_id,
                    "image_url": layer_in.image_url or sticker.image_url,
                    "x": layer_in.x,
                    "y": layer_in.y,
                    "scale": layer_in.scale,
                    "rotation": layer_in.rotation,
                    "z_index": normalized_z_index,
                    "view_image_key": self._normalize_view_image_key(
                        layer_in.view_image_key
                    ),
                    "tint_color_value": layer_in.tint_color_value,
                    "crop_left": crop.left,
                    "crop_top": crop.top,
                    "crop_right": crop.right,
                    "crop_bottom": crop.bottom,
                }
            )

        return self.design_repo.create_with_layers(user_id, design_data, layers_data)
