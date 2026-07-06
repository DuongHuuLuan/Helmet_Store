from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.product_detail_entity import ProductDetailEntity


class ProductDetailRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[ProductDetailEntity]: ...

    @abstractmethod
    def get_by_product_and_color_size(self, product_id: int, color_id: int,
                                      size_id: int) -> Optional[ProductDetailEntity]: ...

    @abstractmethod
    def create(self, product_id: int, color_id: int, size_id: int,
               price: int, is_active: bool = True) -> ProductDetailEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> ProductDetailEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...
