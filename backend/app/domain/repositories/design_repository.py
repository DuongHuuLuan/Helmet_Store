from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.design_entity import DesignEntity


class DesignRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[DesignEntity]: ...

    @abstractmethod
    def get_by_user_id(self, user_id: int) -> list[DesignEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> DesignEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> DesignEntity: ...

    @abstractmethod
    def validate_stickers(self, sticker_ids: list[int], user_id: int) -> tuple[list, list[int]]: ...

    @abstractmethod
    def create_with_layers(self, user_id: int, design_data: dict, layers_data: list[dict]) -> dict: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_by_user_id_with_details(self, user_id: int) -> list[dict]: ...

    @abstractmethod
    def create_share_link(self, design_id: int, share_data: dict) -> dict: ...
