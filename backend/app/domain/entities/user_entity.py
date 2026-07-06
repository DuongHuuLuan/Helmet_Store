from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class UserEntity:
    id: int
    email: str
    username: str
    password: str
    role: str
    created_at: datetime
    updated_at: Optional[datetime] = None
