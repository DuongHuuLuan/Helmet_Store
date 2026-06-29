from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.image_url_entity import ImageUrlEntity


class ImageUrlRepository(ABC):
    @abstractmethod
    def get_by_id(self, id: int) -> Optional[ImageUrlEntity]: ...

    @abstractmethod
    def get_by_product_id(self, product_id: int) -> list[ImageUrlEntity]: ...

    @abstractmethod
    def create(self, product_id: int, url: str, public_id: str,
               color_id: Optional[int] = None,
               view_image_key: Optional[str] = None) -> ImageUrlEntity: ...

    @abstractmethod
    def create_many(self, product_id: int, images: list[dict]) -> list[ImageUrlEntity]: ...

    @abstractmethod
    def update(self, id: int, data: dict) -> ImageUrlEntity: ...

    @abstractmethod
    def delete(self, id: int) -> None: ...

    @abstractmethod
    def delete_all_by_product(self, product_id: int) -> None: ...
