from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.payment_method_entity import PaymentMethodEntity


class PaymentMethodRepository(ABC):
    @abstractmethod
    def get_all_active(self) -> list[PaymentMethodEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict: ...

    @abstractmethod
    def get_by_id(self, id: int) -> Optional[PaymentMethodEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> PaymentMethodEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> PaymentMethodEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def ensure_can_delete(self, id: int) -> None: ...
