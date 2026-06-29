from typing import Optional
from datetime import datetime


class WarehouseEntity:
    def __init__(self, id: int, address: str,
                 capacity: Optional[int] = None,
                 created_at: Optional[datetime] = None,
                 updated_at: Optional[datetime] = None):
        self.id = id
        self.address = address
        self.capacity = capacity
        self.created_at = created_at
        self.updated_at = updated_at


class WarehouseDetailEntity:
    def __init__(self, id: int, warehouse_id: int,
                 product_id: int,
                 color_id: Optional[int] = None,
                 size_id: Optional[int] = None,
                 quantity: int = 0):
        self.id = id
        self.warehouse_id = warehouse_id
        self.product_id = product_id
        self.color_id = color_id
        self.size_id = size_id
        self.quantity = quantity
