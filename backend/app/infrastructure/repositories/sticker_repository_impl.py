import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.sticker_mapper import StickerMapper
from app.domain.entities.sticker_entity import StickerEntity
from app.domain.repositories.sticker_repository import StickerRepository
from app.infrastructure.database.models.sticker import Sticker
from app.infrastructure.database.models.user import User
from app.infrastructure.database.models.design_layer import DesignLayer


class StickerRepositoryImpl(StickerRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[StickerEntity]:
        model = self.db.query(Sticker).filter(Sticker.id == id).first()
        if not model:
            return None
        return StickerMapper.to_entity(model)

    def get_catalog(self, user_id: Optional[int] = None) -> list[StickerEntity]:
        query = self.db.query(Sticker)
        if user_id is None:
            query = query.filter(Sticker.owner_user_id.is_(None))
        else:
            query = query.filter(
                or_(
                    Sticker.owner_user_id.is_(None),
                    Sticker.owner_user_id == user_id,
                )
            )
        models = query.order_by(
            Sticker.owner_user_id.isnot(None).desc(),
            Sticker.id.desc(),
        ).all()
        return [StickerMapper.to_entity(m) for m in models]

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, category: Optional[str] = None,
                scope: str = "system") -> dict:
        normalized_scope = scope.strip().lower()
        base = self.db.query(Sticker).options(joinedload(Sticker.owner))

        if normalized_scope == "system":
            base = base.filter(Sticker.owner_user_id.is_(None))
        else:
            base = base.filter(Sticker.owner_user_id.isnot(None))

        if keyword:
            like = f"%{keyword.strip()}%"
            base = base.outerjoin(User, Sticker.owner_user_id == User.id)
            base = base.filter(
                or_(
                    Sticker.name.ilike(like),
                    Sticker.category.ilike(like),
                    Sticker.image_url.ilike(like),
                    User.username.ilike(like),
                    User.email.ilike(like),
                )
            )

        if category:
            base = base.filter(Sticker.category.ilike(category.strip()))

        total_count = base.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            per_page = max(int(per_page), 1)
            page = max(int(page), 1)

        skip = (page - 1) * per_page
        models = base.order_by(Sticker.id.desc()).offset(skip).limit(per_page).all()

        sticker_ids = [s.id for s in models]
        usage_rows = (
            self.db.query(DesignLayer.sticker_id, func.count(DesignLayer.id).label("usage_count"))
            .filter(DesignLayer.sticker_id.in_(sticker_ids))
            .group_by(DesignLayer.sticker_id)
            .all()
            if sticker_ids else []
        )
        usage_map = {sid: int(cnt or 0) for sid, cnt in usage_rows}

        items = []
        for m in models:
            entity = StickerMapper.to_entity(m)
            usage = usage_map.get(m.id, 0)
            owner = getattr(m, "owner", None)
            is_system = m.owner_user_id is None
            items.append({
                "id": entity.id,
                "owner_user_id": entity.owner_user_id,
                "owner_username": getattr(owner, "username", None),
                "owner_email": getattr(owner, "email", None),
                "name": entity.name,
                "image_url": entity.image_url,
                "public_id": entity.public_id,
                "category": entity.category,
                "is_ai_generated": entity.is_ai_generated,
                "has_transparent_background": entity.has_transparent_background,
                "usage_count": usage,
                "can_edit": is_system,
                "can_delete": is_system and usage == 0,
                "created_at": entity.created_at,
                "updated_at": entity.updated_at,
            })

        last_page = math.ceil(total_count / per_page)
        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def get_system_by_id(self, id: int) -> Optional[StickerEntity]:
        model = self.db.query(Sticker).filter(
            Sticker.id == id,
            Sticker.owner_user_id.is_(None),
        ).first()
        if not model:
            return None
        return StickerMapper.to_entity(model)

    def create(self, data: dict) -> StickerEntity:
        model = Sticker(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return StickerMapper.to_entity(model)

    def update(self, id: int, data: dict) -> StickerEntity:
        model = self.db.query(Sticker).filter(Sticker.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="System sticker not found")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return StickerMapper.to_entity(model)

    def get_by_id_with_details(self, id: int) -> Optional[dict]:
        model = (
            self.db.query(Sticker)
            .options(joinedload(Sticker.owner))
            .filter(Sticker.id == id)
            .first()
        )
        if not model:
            return None

        usage = (
            self.db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == model.id)
            .scalar()
            or 0
        )
        owner = getattr(model, "owner", None)
        is_system = model.owner_user_id is None
        return {
            "id": model.id,
            "owner_user_id": model.owner_user_id,
            "owner_username": getattr(owner, "username", None),
            "owner_email": getattr(owner, "email", None),
            "name": model.name,
            "image_url": model.image_url,
            "public_id": model.public_id,
            "category": model.category,
            "is_ai_generated": model.is_ai_generated,
            "has_transparent_background": model.has_transparent_background,
            "usage_count": usage,
            "can_edit": is_system,
            "can_delete": is_system and usage == 0,
            "created_at": model.created_at,
            "updated_at": model.updated_at,
        }

    def get_system_by_id_with_details(self, id: int) -> Optional[dict]:
        model = (
            self.db.query(Sticker)
            .options(joinedload(Sticker.owner))
            .filter(
                Sticker.id == id,
                Sticker.owner_user_id.is_(None),
            )
            .first()
        )
        if not model:
            return None

        usage = (
            self.db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == model.id)
            .scalar()
            or 0
        )
        owner = getattr(model, "owner", None)
        return {
            "id": model.id,
            "owner_user_id": model.owner_user_id,
            "owner_username": getattr(owner, "username", None),
            "owner_email": getattr(owner, "email", None),
            "name": model.name,
            "image_url": model.image_url,
            "public_id": model.public_id,
            "category": model.category,
            "is_ai_generated": model.is_ai_generated,
            "has_transparent_background": model.has_transparent_background,
            "usage_count": usage,
            "can_edit": True,
            "can_delete": usage == 0,
            "created_at": model.created_at,
            "updated_at": model.updated_at,
        }

    def count_usage(self, sticker_id: int) -> int:
        return (
            self.db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == sticker_id)
            .scalar()
            or 0
        )

    def delete(self, id: int) -> None:
        model = self.db.query(Sticker).filter(Sticker.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="System sticker not found")
        self.db.delete(model)
        self.db.commit()
