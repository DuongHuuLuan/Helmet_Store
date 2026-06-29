from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator


class StickerCrop(BaseModel):
    left: float = Field(default=0.0, ge=0.0, le=1.0)
    top: float = Field(default=0.0, ge=0.0, le=1.0)
    right: float = Field(default=1.0, ge=0.0, le=1.0)
    bottom: float = Field(default=1.0, ge=0.0, le=1.0)

    @model_validator(mode="after")
    def validate_bounds(self):
        if self.left >= self.right:
            raise ValueError("crop.left must be less than crop.right")
        if self.top >= self.bottom:
            raise ValueError("crop.top must be less than crop.bottom")
        return self


class DesignLayerBase(BaseModel):
    sticker_id: int
    image_url: str
    x: float = 0.0
    y: float = 0.0
    scale: float = Field(default=1.0, gt=0.0)
    rotation: float = 0.0
    z_index: int = 0
    view_image_key: Optional[str] = None
    tint_color_value: Optional[int] = None
    crop: StickerCrop = Field(default_factory=StickerCrop)


class DesignLayerIn(DesignLayerBase):
    id: Optional[int] = None


class DesignLayerOut(DesignLayerBase):
    id: int

    @model_validator(mode="before")
    @classmethod
    def inject_crop(cls, data):
        if isinstance(data, dict):
            if data.get("crop") is not None:
                return data

            result = dict(data)
            result["crop"] = {
                "left": result.get("crop_left", 0.0),
                "top": result.get("crop_top", 0.0),
                "right": result.get("crop_right", 1.0),
                "bottom": result.get("crop_bottom", 1.0),
            }
            return result

        return {
            "id": getattr(data, "id"),
            "sticker_id": getattr(data, "sticker_id"),
            "image_url": getattr(data, "image_url"),
            "x": getattr(data, "x"),
            "y": getattr(data, "y"),
            "scale": getattr(data, "scale"),
            "rotation": getattr(data, "rotation"),
            "z_index": getattr(data, "z_index"),
            "view_image_key": getattr(data, "view_image_key", None),
            "tint_color_value": getattr(data, "tint_color_value"),
            "crop": {
                "left": getattr(data, "crop_left", 0.0),
                "top": getattr(data, "crop_top", 0.0),
                "right": getattr(data, "crop_right", 1.0),
                "bottom": getattr(data, "crop_bottom", 1.0),
            },
        }

    class Config:
        from_attributes = True


class DesignBase(BaseModel):
    product_id: int
    product_detail_id: Optional[int] = None
    name: str
    base_image_url: str


class DesignCreate(DesignBase):
    id: Optional[int] = None
    stickers: List[DesignLayerIn] = []
    is_shared: bool = False


class DesignUpdate(DesignBase):
    id: int
    stickers: List[DesignLayerIn] = []
    is_shared: bool = False


class DesignOut(DesignBase):
    id: int
    stickers: List[DesignLayerOut] = []
    is_shared: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    @model_validator(mode="before")
    @classmethod
    def inject_stickers(cls, data):
        if isinstance(data, dict):
            if data.get("stickers") is not None:
                return data

            result = dict(data)
            result["stickers"] = result.get("layers", [])
            return result

        return {
            "id": getattr(data, "id"),
            "product_id": getattr(data, "product_id"),
            "product_detail_id": getattr(data, "product_detail_id", None),
            "name": getattr(data, "name"),
            "base_image_url": getattr(data, "base_image_url"),
            "stickers": list(getattr(data, "layers", []) or []),
            "is_shared": getattr(data, "is_shared"),
            "created_at": getattr(data, "created_at"),
            "updated_at": getattr(data, "updated_at", None),
        }

    class Config:
        from_attributes = True

class DesignListItemOut(BaseModel):
    id: int
    product_id: int
    product_detail_id: Optional[int] = None
    name: str
    base_image_url: str
    is_shared: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class DesignListOut(BaseModel):
    items: List[DesignListItemOut] = []


class DesignShareOut(BaseModel):
    share_url: str


class DesignOrderIn(BaseModel):
    product_detail_id: int
    quantity: int = Field(default=1, gt=0)


class DesignOrderOut(BaseModel):
    message: str
    cart_id: int
    cart_detail_id: int
    design_id: int
