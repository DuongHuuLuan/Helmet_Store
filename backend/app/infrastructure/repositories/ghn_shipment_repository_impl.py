from typing import Any, Optional

from sqlalchemy.orm import Session

from app.domain.repositories.ghn_shipment_repository import GhnShipmentRepository
from app.infrastructure.database.models.ghn import GhnShipment


class GhnShipmentRepositoryImpl(GhnShipmentRepository):
    def __init__(self, db: Session):
        self.db = db

    def create(self, data: dict) -> Any:
        model = GhnShipment(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return model

    def get_by_ghn_order_code(self, ghn_order_code: str) -> Optional[Any]:
        return (
            self.db.query(GhnShipment)
            .filter(GhnShipment.ghn_order_code == ghn_order_code)
            .first()
        )

    def update(self, id: int, data: dict) -> Optional[Any]:
        model = self.db.query(GhnShipment).filter(GhnShipment.id == id).first()
        if model:
            for key, value in data.items():
                setattr(model, key, value)
            self.db.commit()
            self.db.refresh(model)
        return model

    def get_latest_by_order_id(self, order_id: int) -> Optional[Any]:
        return (
            self.db.query(GhnShipment)
            .filter(GhnShipment.order_id == order_id)
            .order_by(GhnShipment.created_at.desc())
            .first()
        )
