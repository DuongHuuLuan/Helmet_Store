from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.cart_entity import CartEntity, CartDetailEntity


class CartRepository(ABC):
    @abstractmethod
    def get_or_create(self, user_id: int) -> CartEntity: ...

    @abstractmethod
    def get_by_user_id(self, user_id: int) -> Optional[CartEntity]: ...

    @abstractmethod
    def find_existing_detail(self, cart_id: int, product_detail_id: int,
                              design_id: Optional[int]) -> Optional[CartDetailEntity]: ...

    @abstractmethod
    def add_detail(self, cart_id: int, product_detail_id: int,
                    design_id: Optional[int], quantity: int) -> CartDetailEntity: ...

    @abstractmethod
    def update_detail_quantity(self, detail_id: int, quantity: int) -> None: ...

    @abstractmethod
    def delete_detail(self, detail_id: int) -> None: ...

    @abstractmethod
    def get_detail_by_id(self, detail_id: int) -> Optional[CartDetailEntity]: ...

    @abstractmethod
    def get_product_detail_by_id(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_design_by_id(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_cart_response(self, user_id: int) -> dict: ...

    @abstractmethod
    def add_to_cart(self, user_id: int, product_detail_id: int,
                    design_id: Optional[int], quantity: int) -> dict: ...

    @abstractmethod
    def update_cart_detail(self, user_id: int, cart_detail_id: int,
                           new_quantity: int) -> dict: ...

    @abstractmethod
    def delete_cart_detail(self, user_id: int, cart_detail_id: int) -> dict: ...
