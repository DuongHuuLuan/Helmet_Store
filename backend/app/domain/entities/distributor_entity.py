from typing import Optional


class DistributorEntity:
    def __init__(self, id: int, name: str,
                 email: Optional[str] = None,
                 address: Optional[str] = None):
        self.id = id
        self.name = name
        self.email = email
        self.address = address
