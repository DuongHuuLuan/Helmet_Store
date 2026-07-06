from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional


@dataclass
class OrderDetailEntity:
    id: int
    order_id: int
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int = 1
    price: Decimal = Decimal("0")
    design_snapshot_json: Optional[dict] = None


@dataclass
class OrderEntity:
    id: int
    user_id: int
    delivery_info_id: int
    payment_method_id: int
    status: str = "pending"
    payment_status: str = "unpaid"
    refund_support_status: str = "none"
    rejection_reason: Optional[str] = None
    reviewed_by_admin_id: Optional[int] = None
    reviewed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
