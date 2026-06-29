from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.sticker_entity import StickerEntity


class StickerRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[StickerEntity]: ...

    @abstractmethod
    def get_catalog(self, user_id: Optional[int] = None) -> list[StickerEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, category: Optional[str] = None,
                scope: str = "system") -> dict: ...

    @abstractmethod
    def get_system_by_id(self, id: int) -> Optional[StickerEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> StickerEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> StickerEntity: ...

    @abstractmethod
    def get_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def get_system_by_id_with_details(self, id: int) -> Optional[dict]: ...

    @abstractmethod
    def count_usage(self, sticker_id: int) -> int: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...
