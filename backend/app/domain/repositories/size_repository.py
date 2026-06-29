from abc import ABC, abstractmethod

from app.domain.entities.size_entity import SizeEntity


class SizeRepository(ABC):
    @abstractmethod
    def get_all(self) -> list[SizeEntity]: ...

    @abstractmethod
    def get_by_id(self, id: int) -> SizeEntity: ...

    @abstractmethod
    def create(self, size: str) -> SizeEntity: ...

    @abstractmethod
    def update(self, id: int, size: str) -> SizeEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def is_used_in_product_detail(self, id: int) -> bool: ...
