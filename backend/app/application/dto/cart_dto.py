from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.application.dto import *
from app.application.dto.product_detail_dto import ProductDetailOut

# dữ liệu khi thêm sản phẩm vào giỏ
class CartDetailCreate(BaseModel):
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int = 1

# dữ liệu khi cập nhật số lượng trong giỏ
class CartDetailUpdate(BaseModel):
    quantity: int

# schema cấu trúc hiển thị một món hàng trong giỏ
class CartDetailOut(BaseModel):
    id: int
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int
    product_detail: ProductDetailOut
    product_id: int
    product_name: str
    image_url: Optional[str] = None
    design_name: Optional[str] = None
    design_preview_image_url: Optional[str] = None

    is_active: bool = True
    available_stock: int = 0
    cart_status: str = "ok"
    status_message: Optional[str] = None
    can_checkout: bool = True

    class Config: 
        from_attributes = True

# schema hiển thị toàn bộ giỏ hàng
class CartOut(BaseModel):
    id: int
    user_id: int
    cart_details: List[CartDetailOut]
    total_price: float = 0
    can_checkout: bool = True

    class Config:
        from_attributes = True
