from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.image_url_mapper import ImageUrlMapper
from app.domain.entities.image_url_entity import ImageUrlEntity
from app.domain.repositories.image_url_repository import ImageUrlRepository
from app.infrastructure.database.models.image_url import ImageURL


class ImageUrlRepositoryImpl(ImageUrlRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[ImageUrlEntity]:
        model = self.db.query(ImageURL).filter(ImageURL.id == id).first()
        if not model:
            return None
        return ImageUrlMapper.to_entity(model)

    def get_by_product_id(self, product_id: int) -> list[ImageUrlEntity]:
        models = self.db.query(ImageURL).filter(ImageURL.product_id == product_id).all()
        return [ImageUrlMapper.to_entity(m) for m in models]

    def create(self, product_id: int, url: str, public_id: str,
               color_id: Optional[int] = None,
               view_image_key: Optional[str] = None) -> ImageUrlEntity:
        model = ImageURL(
            product_id=product_id,
            url=url,
            public_id=public_id,
            color_id=color_id,
            view_image_key=view_image_key,
        )
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ImageUrlMapper.to_entity(model)

    def create_many(self, product_id: int, images: list[dict]) -> list[ImageUrlEntity]:
        entities = []
        for img in images:
            model = ImageURL(
                product_id=product_id,
                url=img["url"],
                public_id=img["public_id"],
                color_id=img.get("color_id"),
                view_image_key=img.get("view_image_key"),
            )
            self.db.add(model)
            entities.append(model)
        self.db.commit()
        for model in entities:
            self.db.refresh(model)
        return [ImageUrlMapper.to_entity(m) for m in entities]

    def update(self, id: int, data: dict) -> ImageUrlEntity:
        model = self.db.query(ImageURL).filter(ImageURL.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy ảnh")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ImageUrlMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(ImageURL).filter(ImageURL.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy ảnh")
        self.db.delete(model)
        self.db.commit()

    def delete_all_by_product(self, product_id: int) -> None:
        self.db.query(ImageURL).filter(ImageURL.product_id == product_id).delete()
        self.db.commit()
