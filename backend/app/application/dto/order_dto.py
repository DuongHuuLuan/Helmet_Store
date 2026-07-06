from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, model_validator
from typing import List, Optional
from app.infrastructure.database.models.order import OrderStatus, PaymentStatus, RefundSupportStatus
from app.application.dto import *
from app.application.dto.discount_dto import DiscountOut
from app.application._image_utils import pick_primary_image


def _enum_value(value):
    return getattr(value, "value", value)

#schema cho delivery info
class DeliveryInfoBase(BaseModel):
    name: str
    address: str
    phone: str
    district_id: Optional[int] = None
    ward_code: Optional[str] = None
    default: bool = False

class DeliveryInfoOut(DeliveryInfoBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

#schema cho Payment method
class PaymentMethodOut(BaseModel):
    id: int
    name: str
    can_delete: bool = True

    class Config:
        from_attributes = True


class PaymentMethodBase(BaseModel):
    name: str


class PaymentMethodCreate(PaymentMethodBase):
    pass


class PaymentMethodUpdate(BaseModel):
    name: Optional[str] = None


class PaymentPaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class PaymentMethodPaginationOut(BaseModel):
    items: List[PaymentMethodOut]
    meta: PaymentPaginationMeta

#schema cho OrderDetail
class OrderDetailOut(BaseModel):
    id: int
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int
    price: Decimal 
    design_snapshot_json: Optional[dict] = None

    product_name: Optional[str] = None
    color_name: Optional[str] = None
    size_name: Optional[str] = None
    image_url: Optional[str] = None
    design_name: Optional[str] = None
    design_preview_image_url: Optional[str] = None

    class Config:
        from_attributes = True

    @model_validator(mode='before')
    @classmethod
    def get_related_data(cls, data):
        product_detail = getattr(data, "product_detail", None)
        result = data
        if not isinstance(data, dict):
            result = {col.name: getattr(data, col.name) for col in data.__table__.columns}

        if product_detail:
            # 1. Lấy thông tin sản phẩm và ảnh
            if product_detail.product:
                result["product_name"] = product_detail.product.name
                if product_detail.product.product_images:
                    chosen_image = pick_primary_image(
                        list(product_detail.product.product_images or []),
                        color_id=getattr(product_detail, "color_id", None),
                    )
                    result["image_url"] = chosen_image.url if chosen_image else None

            # 2. Lấy thông tin màu sắc và kích thước
            if product_detail.color:
                result["color_name"] = product_detail.color.name
            if product_detail.size:
                result["size_name"] = product_detail.size.size

        design = getattr(data, "design", None)
        if design:
            result["design_name"] = getattr(design, "name", None)
            result["design_preview_image_url"] = getattr(
                design,
                "preview_image_url",
                None,
            )
        else:
            snapshot = result.get("design_snapshot_json") or {}
            if isinstance(snapshot, dict):
                result["design_name"] = snapshot.get("name")
                result["design_preview_image_url"] = snapshot.get("preview_image_url")
        
        return result

class OrderItemCreate(BaseModel):
    cart_detail_id: Optional[int] = None
    product_detail_id: Optional[int] = None
    quantity: int

    @model_validator(mode="after")
    def validate_target(self):
        if self.cart_detail_id is None and self.product_detail_id is None:
            raise ValueError("cart_detail_id hoặc product_detail_id là bắt buộc")
        return self

class OrderCreate(BaseModel):
    delivery_info_id: int
    payment_method_id: int
    discount_code: Optional[str] = None
    discount_ids: Optional[List[int]] = None
    order_items: Optional[List[OrderItemCreate]] = None

class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class OrderRejectIn(BaseModel):
    reason: str


#schema cho Order
class OrderOut(BaseModel):
    id: int
    status: str
    payment_status: str = PaymentStatus.UNPAID.value
    refund_support_status: str = RefundSupportStatus.NONE.value
    rejection_reason: Optional[str] = None
    reviewed_by_admin_id: Optional[int] = None
    reviewed_at: Optional[datetime] = None
    created_at: datetime
    shipping_fee: Decimal = Decimal("0")

    delivery_info: Optional[DeliveryInfoOut]
    payment_method: Optional[PaymentMethodOut]
    user: Optional[UserOut] = None
    applied_discounts: List[DiscountOut] = []

    order_details: List[OrderDetailOut] = []

    class Config:
        from_attributes = True

    @model_validator(mode='before')
    @classmethod
    def inject_shipping_fee(cls, data):
        result = data
        if not isinstance(data, dict):
            result = {col.name: getattr(data, col.name) for col in data.__table__.columns}
            for attr in (
                "delivery_info",
                "payment_method",
                "user",
                "order_details",
                "applied_discounts",
                "reviewed_by_admin_id",
                "reviewed_at",
            ):
                if hasattr(data, attr):
                    result[attr] = getattr(data, attr)

        result["status"] = _enum_value(result.get("status")) or OrderStatus.PENDING.value
        result["payment_status"] = (
            _enum_value(result.get("payment_status")) or PaymentStatus.UNPAID.value
        )
        result["refund_support_status"] = (
            _enum_value(result.get("refund_support_status"))
            or RefundSupportStatus.NONE.value
        )

        shipping_fee = result.get("shipping_fee")
        if shipping_fee is None:
            ghn_shipments = None
            if isinstance(data, dict):
                ghn_shipments = data.get("ghn_shipments")
            else:
                ghn_shipments = getattr(data, "ghn_shipments", None)

            fee_value = Decimal("0")
            if ghn_shipments:
                ordered_shipments = sorted(
                    list(ghn_shipments),
                    key=lambda item: (
                        getattr(item, "created_at", None)
                        if not isinstance(item, dict)
                        else item.get("created_at"),
                        getattr(item, "id", 0)
                        if not isinstance(item, dict)
                        else item.get("id", 0),
                    ),
                    reverse=True,
                )
                first = ordered_shipments[0]
                raw_fee = (
                    getattr(first, "shipping_fee", None)
                    if not isinstance(first, dict)
                    else first.get("shipping_fee")
                )
                if raw_fee is not None:
                    fee_value = Decimal(str(raw_fee))
            result["shipping_fee"] = fee_value

        return result


class OrderPaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class OrderPaginationOut(BaseModel):
    items: List[OrderOut]
    meta: OrderPaginationMeta
