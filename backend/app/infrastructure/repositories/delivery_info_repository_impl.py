from typing import Optional

from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.delivery_info_mapper import DeliveryInfoMapper
from app.domain.entities.delivery_info_entity import DeliveryInfoEntity
from app.domain.repositories.delivery_info_repository import DeliveryInfoRepository
from app.infrastructure.database.models.delivery import DeliveryInfo


class DeliveryInfoRepositoryImpl(DeliveryInfoRepository):
    def __init__(self, db: Session):
        self.db = db

    def create(self, user_id: int, data: dict) -> DeliveryInfoEntity:
        if data.get("default"):
            existing = self.db.query(DeliveryInfo).filter(DeliveryInfo.user_id == user_id).first()

        model = DeliveryInfo(**data, user_id=user_id)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return DeliveryInfoMapper.to_entity(model)

    def get_by_user_id(self, user_id: int) -> list[DeliveryInfoEntity]:
        models = self.db.query(DeliveryInfo).filter(DeliveryInfo.user_id == user_id).all()
        return [DeliveryInfoMapper.to_entity(m) for m in models]

    def get_by_id(self, delivery_id: int) -> Optional[DeliveryInfoEntity]:
        model = self.db.query(DeliveryInfo).filter(DeliveryInfo.id == delivery_id).first()
        if not model:
            return None
        return DeliveryInfoMapper.to_entity(model)

    def delete(self, delivery_id: int, user_id: int) -> None:
        model = self.db.query(DeliveryInfo).filter(
            DeliveryInfo.id == delivery_id,
            DeliveryInfo.user_id == user_id,
        ).first()
        if model:
            self.db.delete(model)
            self.db.commit()
