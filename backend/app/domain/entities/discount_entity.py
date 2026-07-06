from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional


@dataclass
class DiscountEntity:
    id: int
    category_id: int
    name: str
    description: Optional[str] = None
    percent: Decimal = Decimal("0")
    status: str = "active"
    start_at: datetime = None
    end_at: datetime = None
    created_at: Optional[datetime] = None
