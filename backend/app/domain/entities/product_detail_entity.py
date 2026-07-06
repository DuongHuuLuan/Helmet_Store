from dataclasses import dataclass
from typing import Optional


@dataclass
class ProductDetailEntity:
    id: int
    product_id: int
    color_id: int
    size_id: int
    price: Optional[int] = None
    is_active: bool = True
