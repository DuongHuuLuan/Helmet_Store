from typing import Optional


class PaymentMethodEntity:
    def __init__(self, id: int, name: str, can_delete: bool = True):
        self.id = id
        self.name = name
        self.can_delete = can_delete
