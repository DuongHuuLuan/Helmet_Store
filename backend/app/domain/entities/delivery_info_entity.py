from typing import Optional
from datetime import datetime


class DeliveryInfoEntity:
    def __init__(self, id: int, user_id: int, name: str, address: str, phone: str,
                 district_id: Optional[int] = None, ward_code: Optional[str] = None,
                 default: bool = False,
                 created_at: Optional[datetime] = None, updated_at: Optional[datetime] = None):
        self.id = id
        self.user_id = user_id
        self.name = name
        self.address = address
        self.phone = phone
        self.district_id = district_id
        self.ward_code = ward_code
        self.default = default
        self.created_at = created_at
        self.updated_at = updated_at
