from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.product_entity import ProductEntity


class ProductRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[ProductEntity]: ...

    @abstractmethod
    def create(self, name: str, category_id: int, description: Optional[str] = None,
               unit: str = "Chiếc") -> ProductEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> ProductEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, category_id: Optional[int] = None) -> dict: ...

    @abstractmethod
    def exists_by_id(self, id: int) -> bool: ...

    @abstractmethod
    def ensure_can_delete(self, id: int) -> None: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_all_with_details(self, page: int = 1, per_page: Optional[int] = None,
                              keyword: Optional[str] = None, category_id: Optional[int] = None) -> dict: ...

    @abstractmethod
    def count_all(self) -> int: ...
