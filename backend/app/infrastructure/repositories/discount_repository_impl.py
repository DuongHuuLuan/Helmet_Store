import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.discount_mapper import DiscountMapper
from app.domain.entities.discount_entity import DiscountEntity
from app.domain.repositories.discount_repository import DiscountRepository
from app.infrastructure.database.models.discount import Discount, DiscountStatus, OrderDiscount


class DiscountRepositoryImpl(DiscountRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[DiscountEntity]:
        model = self.db.query(Discount).filter(Discount.id == id).first()
        if not model:
            return None
        return DiscountMapper.to_entity(model)

    def _get_blocked_ids(self, discount_ids: list[int]) -> set[int]:
        if not discount_ids:
            return set()
        rows = (
            self.db.query(OrderDiscount.discount_id)
            .filter(OrderDiscount.discount_id.in_(discount_ids))
            .distinct()
            .all()
        )
        return {row[0] for row in rows if row[0] is not None}

    def ensure_can_delete(self, id: int) -> None:
        model = self.db.query(Discount).filter(Discount.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy khuyến mãi")
        blocked = self._get_blocked_ids([id])
        if id in blocked:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Không thể xóa khuyến mãi đã áp dụng cho đơn hàng.")

    def create(self, data: dict) -> DiscountEntity:
        model = Discount(**data, status=DiscountStatus.ACTIVE)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return DiscountMapper.to_entity(model)

    def update(self, id: int, data: dict) -> DiscountEntity:
        model = self.db.query(Discount).filter(Discount.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy khuyến mãi")

        status_value = data.pop("status", None)
        if status_value is not None:
            if isinstance(status_value, DiscountStatus):
                model.status = status_value
            else:
                try:
                    model.status = DiscountStatus(status_value)
                except ValueError:
                    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Trạng thái không hợp lệ")

        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return DiscountMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Discount).filter(Discount.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy khuyến mãi")
        self.db.delete(model)
        self.db.commit()

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        from sqlalchemy import or_
        query = self.db.query(Discount)

        if keyword:
            like = f"%{keyword}%"
            query = query.filter(or_(Discount.name.ilike(like), Discount.description.ilike(like)))

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
        models = query.order_by(Discount.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)
        blocked_ids = self._get_blocked_ids([m.id for m in models])

        items = []
        for m in models:
            entity = DiscountMapper.to_entity(m)
            items.append({
                "id": entity.id, "category_id": entity.category_id,
                "name": entity.name, "description": entity.description,
                "percent": entity.percent, "status": entity.status,
                "start_at": entity.start_at, "end_at": entity.end_at,
                "created_at": entity.created_at, "can_delete": entity.id not in blocked_ids,
            })

        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def _build_discount_dict(self, model, blocked_ids: set[int] | None = None) -> dict:
        can_delete = True
        if blocked_ids is not None:
            can_delete = model.id not in blocked_ids
        return {
            "id": model.id, "category_id": model.category_id,
            "name": model.name, "description": model.description,
            "percent": model.percent, "status": model.status.value if hasattr(model.status, 'value') else model.status,
            "start_at": model.start_at, "end_at": model.end_at,
            "created_at": model.created_at, "can_delete": can_delete,
        }

    def get_by_id_with_details(self, id: int) -> Optional[dict]:
        model = self.db.query(Discount).filter(Discount.id == id).first()
        if not model:
            return None
        blocked = self._get_blocked_ids([id])
        return self._build_discount_dict(model, blocked)

    def get_valid_by_name(self, name: str) -> Optional[dict]:
        from datetime import datetime
        now = datetime.now()
        model = self.db.query(Discount).filter(
            Discount.name.ilike((name or "").strip()),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).first()
        if not model:
            return None
        return self._build_discount_dict(model)

    def get_grouped_by_category_ids(self, category_ids: list[int]) -> dict:
        if not category_ids:
            return {}
        from datetime import datetime
        now = datetime.now()
        models = self.db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).order_by(Discount.category_id, Discount.start_at.desc(), Discount.id.desc()).all()

        result = {}
        for m in models:
            if m.category_id not in result:
                result[m.category_id] = self._build_discount_dict(m)
        return result

    def get_valid_for_categories(self, category_ids: list[int]) -> list[dict]:
        if not category_ids:
            return []
        from datetime import datetime
        now = datetime.now()
        models = self.db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).all()
        return [self._build_discount_dict(m) for m in models]

    def list_valid_for_categories(self, category_ids: list[int], limit: Optional[int] = None) -> list[dict]:
        if not category_ids:
            return []
        from datetime import datetime
        now = datetime.now()
        query = self.db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).order_by(
            Discount.percent.desc(),
            Discount.end_at.asc(),
            Discount.id.desc(),
        )
        if isinstance(limit, int) and limit > 0:
            query = query.limit(limit)
        return [self._build_discount_dict(m) for m in query.all()]

    def get_active_discounts(self, limit: Optional[int] = None, keyword: Optional[str] = None) -> list[dict]:
        from datetime import datetime
        from sqlalchemy import or_
        now = datetime.now()
        query = self.db.query(Discount).filter(
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        )
        cleaned_keyword = (keyword or "").strip()
        if cleaned_keyword:
            like = f"%{cleaned_keyword}%"
            query = query.filter(
                or_(
                    Discount.name.ilike(like),
                    Discount.description.ilike(like),
                )
            )
        query = query.order_by(
            Discount.percent.desc(),
            Discount.end_at.asc(),
            Discount.id.desc(),
        )
        if isinstance(limit, int) and limit > 0:
            query = query.limit(limit)
        return [self._build_discount_dict(m) for m in query.all()]
