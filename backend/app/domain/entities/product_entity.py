from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class ProductEntity:
    id: int
    category_id: int
    name: str
    description: Optional[str] = None
    unit: str = "Chiếc"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
