from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.color_mapper import ColorMapper
from app.domain.entities.color_entity import ColorEntity
from app.domain.repositories.color_repository import ColorRepository
from app.infrastructure.database.models.color import Color


class ColorRepositoryImpl(ColorRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> list[ColorEntity]:
        models = self.db.query(Color).all()
        return [ColorMapper.to_entity(m) for m in models]

    def get_by_id(self, id: int) -> ColorEntity:
        model = self.db.query(Color).filter(Color.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy màu sắc",
            )
        return ColorMapper.to_entity(model)

    def create(self, name: str, hexcode: str) -> ColorEntity:
        model = Color(name=name, hexcode=hexcode)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ColorMapper.to_entity(model)

    def update(self, id: int, name: str, hexcode: str) -> ColorEntity:
        model = self.db.query(Color).filter(Color.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy màu sắc",
            )
        model.name = name
        model.hexcode = hexcode
        self.db.commit()
        self.db.refresh(model)
        return ColorMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Color).filter(Color.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy màu sắc",
            )
        self.db.delete(model)
        self.db.commit()
