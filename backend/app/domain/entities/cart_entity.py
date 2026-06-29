from dataclasses import dataclass
from typing import Optional


@dataclass
class CartEntity:
    id: int
    user_id: int


@dataclass
class CartDetailEntity:
    id: int
    cart_id: int
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int = 1
