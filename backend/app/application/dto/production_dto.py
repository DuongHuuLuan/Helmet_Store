from typing import Any, List, Optional

from pydantic import BaseModel, Field


class ProductionLayerSpecOut(BaseModel):
    sticker_id: Optional[int] = None
    sticker_name: Optional[str] = None
    image_url: Optional[str] = None
    view_image_key: Optional[str] = None
    x: float
    y: float
    scale: float
    rotation: float
    rotation_degrees: float = 0.0
    z_index: int
    crop: Optional[dict[str, Any]] = None
    render_width_mm: Optional[float] = None
    render_height_mm: Optional[float] = None
    box_size_mm: Optional[float] = None
    position_label: Optional[str] = None
    box_size_px: Optional[float] = None
    left_px: Optional[float] = None
    top_px: Optional[float] = None
    visible_width_px: Optional[float] = None
    visible_height_px: Optional[float] = None
    visible_offset_x_px: Optional[float] = None
    visible_offset_y_px: Optional[float] = None


class ProductionViewOut(BaseModel):
    view_image_key: Optional[str] = None
    label: Optional[str] = None
    base_image_url: Optional[str] = None
    preview_image_url: Optional[str] = None
    layers: List[ProductionLayerSpecOut] = Field(default_factory=list)


class ProductionOrderDetailOut(BaseModel):
    order_detail_id: int
    product_detail_id: int
    product_name: Optional[str] = None
    quantity: int
    base_image_url: Optional[str] = None
    preview_image_url: Optional[str] = None
    design_snapshot_json: Optional[dict[str, Any]] = None
    canvas_width_px: float
    canvas_height_px: float
    printable_width_mm: float
    printable_height_mm: float
    layers: List[ProductionLayerSpecOut] = Field(default_factory=list)
    views: List[ProductionViewOut] = Field(default_factory=list)


class OrderProductionOut(BaseModel):
    order_id: int
    status: str
    payment_status: str
    refund_support_status: str
    rejection_reason: Optional[str] = None
    items: List[ProductionOrderDetailOut] = Field(default_factory=list)
