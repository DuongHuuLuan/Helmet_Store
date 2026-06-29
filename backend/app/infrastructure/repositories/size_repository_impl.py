from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.size_mapper import SizeMapper
from app.domain.entities.size_entity import SizeEntity
from app.domain.repositories.size_repository import SizeRepository
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.size import Size


class SizeRepositoryImpl(SizeRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> list[SizeEntity]:
        models = self.db.query(Size).all()
        return [SizeMapper.to_entity(m) for m in models]

    def get_by_id(self, id: int) -> SizeEntity:
        model = self.db.query(Size).filter(Size.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy kích thước",
            )
        return SizeMapper.to_entity(model)

    def create(self, size: str) -> SizeEntity:
        model = Size(size=size)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return SizeMapper.to_entity(model)

    def update(self, id: int, size: str) -> SizeEntity:
        model = self.db.query(Size).filter(Size.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy kích thước",
            )
        model.size = size
        self.db.commit()
        self.db.refresh(model)
        return SizeMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Size).filter(Size.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy kích thước",
            )
        self.db.delete(model)
        self.db.commit()

    def is_used_in_product_detail(self, id: int) -> bool:
        return (
            self.db.query(ProductDetail)
            .filter(ProductDetail.size_id == id)
            .first()
            is not None
        )
