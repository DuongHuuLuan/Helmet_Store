from typing import Optional


class DesignLayerEntity:
    def __init__(self, id: int, design_id: int, sticker_id: int,
                 image_url: str, x: float = 0.0, y: float = 0.0,
                 scale: float = 1.0, rotation: float = 0.0,
                 z_index: int = 0,
                 view_image_key: Optional[str] = None,
                 tint_color_value: Optional[int] = None,
                 crop_left: float = 0.0, crop_top: float = 0.0,
                 crop_right: float = 1.0, crop_bottom: float = 1.0):
        self.id = id
        self.design_id = design_id
        self.sticker_id = sticker_id
        self.image_url = image_url
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.z_index = z_index
        self.view_image_key = view_image_key
        self.tint_color_value = tint_color_value
        self.crop_left = crop_left
        self.crop_top = crop_top
        self.crop_right = crop_right
        self.crop_bottom = crop_bottom
