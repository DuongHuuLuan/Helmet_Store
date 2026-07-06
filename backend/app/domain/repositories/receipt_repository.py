from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.receipt_entity import ReceiptEntity


class ReceiptRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[ReceiptEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict: ...

    @abstractmethod
    def create(self, data: dict) -> ReceiptEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> ReceiptEntity: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def create_with_details(self, data: dict, details_data: list[dict]) -> dict: ...

    @abstractmethod
    def confirm_receipt(self, id: int) -> dict: ...

    @abstractmethod
    def cancel_receipt(self, id: int) -> dict: ...
