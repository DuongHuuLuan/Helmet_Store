from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.distributor_entity import DistributorEntity


class DistributorRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[DistributorEntity]: ...

    @abstractmethod
    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict: ...

    @abstractmethod
    def create(self, data: dict) -> DistributorEntity: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> DistributorEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def get_blocked_ids(self, ids: list[int]) -> set[int]: ...
