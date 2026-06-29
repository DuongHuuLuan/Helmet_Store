from abc import ABC, abstractmethod

from app.domain.entities.category_entity import CategoryEntity


class CategoryRepository(ABC):
    @abstractmethod
    def get_all(self) -> list[CategoryEntity]: ...

    @abstractmethod
    def get_all_paginated(
        self,
        page: int = 1,
        per_page: int | None = None,
        keyword: str | None = None,
    ) -> tuple[list[tuple[CategoryEntity, int]], int]: ...

    @abstractmethod
    def get_by_id(self, id: int) -> CategoryEntity: ...

    @abstractmethod
    def get_product_count(self, id: int) -> int: ...

    @abstractmethod
    def create(self, name: str) -> CategoryEntity: ...

    @abstractmethod
    def update(self, id: int, name: str) -> CategoryEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def exists_by_name(self, name: str) -> bool: ...

    @abstractmethod
    def is_used_in_products(self, id: int) -> bool: ...

    @abstractmethod
    def get_products_by_category(self, id: int) -> list: ...
