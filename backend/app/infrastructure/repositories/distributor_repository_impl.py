import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.distributor_mapper import DistributorMapper
from app.domain.entities.distributor_entity import DistributorEntity
from app.domain.repositories.distributor_repository import DistributorRepository
from app.infrastructure.database.models.distributor import Distributor
from app.infrastructure.database.models.receipt import Receipt


class DistributorRepositoryImpl(DistributorRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[DistributorEntity]:
        model = self.db.query(Distributor).filter(Distributor.id == id).first()
        if not model:
            return None
        return DistributorMapper.to_entity(model)

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        query = self.db.query(Distributor)
        if keyword:
            query = query.filter(Distributor.name.ilike(f"%{keyword}%"))

        total_count = query.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            per_page = max(per_page, 1)
            page = max(page, 1)

        skip = (page - 1) * per_page
        models = query.order_by(Distributor.id.desc()).offset(skip).limit(per_page).all()

        ids = [m.id for m in models]
        blocked = self.get_blocked_ids(ids)

        items = []
        for m in models:
            entity = DistributorMapper.to_entity(m)
            items.append({
                "id": entity.id,
                "name": entity.name,
                "email": entity.email,
                "address": entity.address,
                "can_delete": entity.id not in blocked,
            })

        last_page = math.ceil(total_count / per_page)
        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def get_blocked_ids(self, ids: list[int]) -> set[int]:
        if not ids:
            return set()
        rows = (
            self.db.query(Receipt.distributor_id)
            .filter(Receipt.distributor_id.in_(ids))
            .distinct()
            .all()
        )
        return {row[0] for row in rows if row[0] is not None}

    def create(self, data: dict) -> DistributorEntity:
        model = Distributor(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return DistributorMapper.to_entity(model)

    def update(self, id: int, data: dict) -> DistributorEntity:
        model = self.db.query(Distributor).filter(Distributor.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nhà cung cấp không tồn tại")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return DistributorMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Distributor).filter(Distributor.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nhà cung cấp không tồn tại")
        blocked = self.get_blocked_ids([id])
        if id in blocked:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không thể xóa nhà cung cấp đã có phiếu nhập.",
            )
        self.db.delete(model)
        self.db.commit()
