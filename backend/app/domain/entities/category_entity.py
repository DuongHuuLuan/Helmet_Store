from dataclasses import dataclass
from datetime import datetime


@dataclass
class CategoryEntity:
    id: int
    name: str
    created_at: datetime
