from abc import ABC, abstractmethod
from app.domain.entities.color_entity import ColorEntity


class ColorRepository(ABC):
    @abstractmethod
    def get_all(self) -> list[ColorEntity]: ...

    @abstractmethod
    def get_by_id(self, id: int) -> ColorEntity: ...

    @abstractmethod
    def create(self, name: str, hexcode: str) -> ColorEntity: ...

    @abstractmethod
    def update(self, id: int, name: str, hexcode: str) -> ColorEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...
