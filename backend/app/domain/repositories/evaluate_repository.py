from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.evaluate_entity import EvaluateEntity


class EvaluateRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[EvaluateEntity]: ...

    @abstractmethod
    def get_by_order_id(self, order_id: int) -> Optional[EvaluateEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> EvaluateEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> EvaluateEntity: ...

    @abstractmethod
    def get_order_info(self, order_id: int) -> Optional[dict]: ...

    @abstractmethod
    def exists_by_order_id(self, order_id: int) -> bool: ...

    @abstractmethod
    def create_evaluate_with_images(self, data: dict, image_urls: list[str]) -> dict: ...

    @abstractmethod
    def get_evaluate_by_id_with_details(self, evaluate_id: int, user_id: Optional[int] = None, is_admin: bool = False) -> Optional[dict]: ...

    @abstractmethod
    def get_evaluate_by_order_with_details(self, order_id: int, user_id: Optional[int] = None, is_admin: bool = False) -> Optional[dict]: ...

    @abstractmethod
    def get_admin_evaluations_paginated(self, page: int, per_page: int, order_id: Optional[int] = None, has_reply: Optional[bool] = None) -> dict: ...

    @abstractmethod
    def get_my_evaluations_paginated(self, user_id: int, page: int, per_page: int) -> dict: ...

    @abstractmethod
    def get_product_evaluations_data(self, product_id: int, page: int, per_page: int) -> dict: ...

    @abstractmethod
    def reply_to_evaluate(self, evaluate_id: int, admin_id: int, reply: str) -> Optional[dict]: ...
