from abc import ABC, abstractmethod
from typing import Any, Optional


class GhnShipmentRepository(ABC):
    @abstractmethod
    def create(self, data: dict) -> Any: ...

    @abstractmethod
    def get_by_ghn_order_code(self, ghn_order_code: str) -> Optional[Any]: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> Optional[Any]: ...

    @abstractmethod
    def get_latest_by_order_id(self, order_id: int) -> Optional[Any]: ...
