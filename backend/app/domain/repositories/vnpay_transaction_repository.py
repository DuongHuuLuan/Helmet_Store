from abc import ABC, abstractmethod
from typing import Any


class VnPayTransactionRepository(ABC):
    @abstractmethod
    def create(self, data: dict) -> Any: ...

    @abstractmethod
    def get_by_order_id(self, order_id: int) -> list[Any]: ...
