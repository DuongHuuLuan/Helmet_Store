from abc import ABC, abstractmethod
from datetime import date
from typing import Any, Optional


class OrderRepository(ABC):
    @abstractmethod
    def create_order(
        self,
        user_id: int,
        delivery_info_id: int,
        payment_method_id: int,
        discount_ids: Optional[list[int]] = None,
        order_items: Optional[list[dict]] = None,
    ) -> Any: ...

    @abstractmethod
    def get_by_id(self, id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_user_orders(self, user_id: int) -> list: ...

    @abstractmethod
    def get_latest_order(self, user_id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_admin_orders(
        self,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> dict: ...

    @abstractmethod
    def get_user_order_by_id(self, user_id: int, order_id: int) -> Optional[Any]: ...

    @abstractmethod
    def get_admin_order_by_id(self, order_id: int) -> Optional[Any]: ...

    @abstractmethod
    def update_status(self, order_id: int, status: str) -> Any: ...

    @abstractmethod
    def cancel_order(self, order_id: int, user_id: int) -> None: ...

    @abstractmethod
    def delete_order(self, order_id: int, user_id: int) -> dict: ...

    @abstractmethod
    def approve_order(self, order_id: int, admin_id: int) -> Any: ...

    @abstractmethod
    def reject_order(self, order_id: int, admin_id: int, reason: str) -> Any: ...

    @abstractmethod
    def confirm_delivery(self, order_id: int, user_id: int) -> Any: ...

    @abstractmethod
    def get_order_where(self, **kwargs) -> Optional[Any]: ...

    @abstractmethod
    def count_by_payment_method(self, payment_method_id: int) -> int: ...

    @abstractmethod
    def sync_payment_statuses(self, orders: list) -> list: ...

    @abstractmethod
    def update_payment_status(self, order_id: int, payment_status: str) -> None: ...

    @abstractmethod
    def count_orders_today(self, today: date) -> int: ...

    @abstractmethod
    def sum_revenue_today(self, today: date) -> float: ...
