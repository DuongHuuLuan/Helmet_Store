from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.delivery_info_entity import DeliveryInfoEntity


class DeliveryInfoRepository(ABC):
    @abstractmethod
    def create(self, user_id: int, data: dict) -> DeliveryInfoEntity: ...

    @abstractmethod
    def get_by_user_id(self, user_id: int) -> list[DeliveryInfoEntity]: ...

    @abstractmethod
    def get_by_id(self, delivery_id: int) -> Optional[DeliveryInfoEntity]: ...

    @abstractmethod
    def delete(self, delivery_id: int, user_id: int) -> None: ...
