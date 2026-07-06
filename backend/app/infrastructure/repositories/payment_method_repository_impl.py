import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.payment_method_mapper import PaymentMethodMapper
from app.domain.entities.payment_method_entity import PaymentMethodEntity
from app.domain.repositories.payment_method_repository import PaymentMethodRepository
from app.infrastructure.database.models.payment import PaymentMethod
from app.infrastructure.database.models.order import Order


class PaymentMethodRepositoryImpl(PaymentMethodRepository):
    def __init__(self, db: Session):
        self.db = db

    def _get_blocked_ids(self, payment_ids: list[int]) -> set[int]:
        if not payment_ids:
            return set()
        rows = (
            self.db.query(Order.payment_method_id)
            .filter(Order.payment_method_id.in_(payment_ids))
            .distinct()
            .all()
        )
        return {row[0] for row in rows if row[0] is not None}

    def ensure_can_delete(self, id: int) -> None:
        model = self.db.query(PaymentMethod).filter(PaymentMethod.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phương thức thanh toán")
        blocked = self._get_blocked_ids([id])
        if id in blocked:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Không thể xóa phương thức thanh toán đã dùng trong đơn hàng.")

    def get_all_active(self) -> list[PaymentMethodEntity]:
        models = self.db.query(PaymentMethod).all()
        return [PaymentMethodMapper.to_entity(m) for m in models]

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        query = self.db.query(PaymentMethod)

        if keyword:
            query = query.filter(PaymentMethod.name.ilike(f"%{keyword}%"))

        total_count = query.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1: per_page = 1
            if page < 1: page = 1

        skip = (page - 1) * per_page
        models = query.order_by(PaymentMethod.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)
        blocked_ids = self._get_blocked_ids([m.id for m in models])

        items = []
        for m in models:
            entity = PaymentMethodMapper.to_entity(m)
            items.append({
                "id": entity.id, "name": entity.name,
                "can_delete": entity.id not in blocked_ids,
            })

        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def get_by_id(self, id: int) -> Optional[PaymentMethodEntity]:
        model = self.db.query(PaymentMethod).filter(PaymentMethod.id == id).first()
        if not model:
            return None
        entity = PaymentMethodMapper.to_entity(model)
        blocked = self._get_blocked_ids([id])
        entity.can_delete = id not in blocked
        return entity

    def create(self, data: dict) -> PaymentMethodEntity:
        model = PaymentMethod(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return PaymentMethodMapper.to_entity(model)

    def update(self, id: int, data: dict) -> PaymentMethodEntity:
        model = self.db.query(PaymentMethod).filter(PaymentMethod.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phương thức thanh toán")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return PaymentMethodMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(PaymentMethod).filter(PaymentMethod.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phương thức thanh toán")
        self.db.delete(model)
        self.db.commit()
