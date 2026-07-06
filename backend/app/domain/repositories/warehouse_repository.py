from abc import ABC, abstractmethod
from typing import Any, Optional
from app.domain.entities.warehouse_entity import WarehouseEntity


class WarehouseRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[WarehouseEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict: ...

    @abstractmethod
    def create(self, data: dict) -> WarehouseEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> WarehouseEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def get_total_stock(self, product_id: int, size_id: int, color_id: int) -> int: ...

    @abstractmethod
    def get_with_summary(self, id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_detail_list(self, warehouse_id: int, page: int = 1,
                        per_page: Optional[int] = None,
                        keyword: Optional[str] = None,
                        category_id: Optional[int] = None) -> dict: ...

    @abstractmethod
    def decrease_stock(self, product_id: int, color_id: int, size_id: int, quantity: int) -> None: ...

    @abstractmethod
    def increase_stock(self, product_id: int, color_id: int, size_id: int, quantity: int) -> None: ...

    @abstractmethod
    def get_total_stock_for_detail(self, product_detail) -> int: ...
