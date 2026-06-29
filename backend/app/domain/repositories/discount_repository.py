from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.discount_entity import DiscountEntity


class DiscountRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[DiscountEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict: ...

    @abstractmethod
    def create(self, data: dict) -> DiscountEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> DiscountEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def ensure_can_delete(self, id: int) -> None: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_valid_by_name(self, name: str) -> Optional[dict]: ...

    @abstractmethod
    def get_grouped_by_category_ids(self, category_ids: list[int]) -> dict: ...

    @abstractmethod
    def get_valid_for_categories(self, category_ids: list[int]) -> list[dict]: ...

    @abstractmethod
    def list_valid_for_categories(self, category_ids: list[int], limit: Optional[int] = None) -> list[dict]: ...

    @abstractmethod
    def get_active_discounts(self, limit: Optional[int] = None, keyword: Optional[str] = None) -> list[dict]: ...
