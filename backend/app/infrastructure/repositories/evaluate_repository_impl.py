from typing import Optional
from datetime import datetime

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.evaluate_mapper import EvaluateMapper
from app.domain.entities.evaluate_entity import EvaluateEntity
from app.domain.repositories.evaluate_repository import EvaluateRepository
from app.infrastructure.database.models.evaluate import Evaluate
from app.infrastructure.database.models.order import Order, OrderDetail
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.evaluate_image import EvaluateImage


class EvaluateRepositoryImpl(EvaluateRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[EvaluateEntity]:
        model = self.db.query(Evaluate).filter(Evaluate.id == id).first()
        if not model:
            return None
        return EvaluateMapper.to_entity(model)

    def get_by_order_id(self, order_id: int) -> Optional[EvaluateEntity]:
        model = self.db.query(Evaluate).filter(Evaluate.order_id == order_id).first()
        if not model:
            return None
        return EvaluateMapper.to_entity(model)

    def create(self, data: dict) -> EvaluateEntity:
        model = Evaluate(**data)
        self.db.add(model)
        self.db.flush()
        return EvaluateMapper.to_entity(model)

    def update(self, id: int, data: dict) -> EvaluateEntity:
        model = self.db.query(Evaluate).filter(Evaluate.id == id).first()
        if not model:
            return None
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return EvaluateMapper.to_entity(model)

    def get_order_info(self, order_id: int) -> Optional[dict]:
        model = self.db.query(Order).filter(Order.id == order_id).first()
        if not model:
            return None
        return {
            "user_id": model.user_id,
            "status": model.status.value,
        }

    def exists_by_order_id(self, order_id: int) -> bool:
        return self.db.query(Evaluate).filter(Evaluate.order_id == order_id).first() is not None

    def create_evaluate_with_images(self, data: dict, image_urls: list[str]) -> dict:
        model = Evaluate(**data)
        self.db.add(model)
        self.db.flush()

        for idx, url in enumerate(image_urls):
            self.db.add(EvaluateImage(evaluate_id=model.id, image_url=url, sort_order=idx))

        self.db.commit()

        result = (
            self.db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == model.id)
            .first()
        )
        return self._evaluate_to_dict(result)

    def get_evaluate_by_id_with_details(self, evaluate_id: int, user_id: Optional[int] = None, is_admin: bool = False) -> Optional[dict]:
        query = (
            self.db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
        )
        if not is_admin and user_id is not None:
            query = query.filter(Evaluate.user_id == user_id)
        model = query.first()
        if not model:
            return None
        return self._evaluate_to_dict(model)

    def get_evaluate_by_order_with_details(self, order_id: int, user_id: Optional[int] = None, is_admin: bool = False) -> Optional[dict]:
        query = (
            self.db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.order_id == order_id)
        )
        if not is_admin and user_id is not None:
            query = query.filter(Evaluate.user_id == user_id)
        model = query.first()
        if not model:
            return None
        return self._evaluate_to_dict(model)

    def get_admin_evaluations_paginated(self, page: int, per_page: int, order_id: Optional[int] = None, has_reply: Optional[bool] = None) -> dict:
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = self.db.query(Evaluate).options(joinedload(Evaluate.images))

        if order_id is not None:
            query = query.filter(Evaluate.order_id == order_id)
        if has_reply is True:
            query = query.filter(Evaluate.admin_reply.isnot(None))
        elif has_reply is False:
            query = query.filter(Evaluate.admin_reply.is_(None))

        total = query.count()
        items = (
            query.order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )
        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": [self._evaluate_to_dict(item) for item in items],
            "meta": {"page": page, "per_page": per_page, "total": total, "total_pages": total_pages},
        }

    def get_my_evaluations_paginated(self, user_id: int, page: int, per_page: int) -> dict:
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = (
            self.db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.user_id == user_id)
        )
        total = query.count()
        items = (
            query.order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )
        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": [self._evaluate_to_dict(item) for item in items],
            "meta": {"page": page, "per_page": per_page, "total": total, "total_pages": total_pages},
        }

    def get_product_evaluations_data(self, product_id: int, page: int, per_page: int) -> dict:
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        evaluate_sq = (
            self.db.query(
                Evaluate.id.label("evaluate_id"),
                func.max(Evaluate.rate).label("rate"),
                func.max(Evaluate.content).label("content"),
                func.max(Evaluate.created_at).label("created_at"),
            )
            .join(Order, Order.id == Evaluate.order_id)
            .join(OrderDetail, OrderDetail.order_id == Order.id)
            .join(ProductDetail, ProductDetail.id == OrderDetail.product_detail_id)
            .filter(ProductDetail.product_id == product_id)
            .group_by(Evaluate.id)
            .subquery()
        )

        total = self.db.query(func.count()).select_from(evaluate_sq).scalar() or 0

        avg_rate = self.db.query(func.avg(evaluate_sq.c.rate)).select_from(evaluate_sq).scalar() or 0

        rate_rows = (
            self.db.query(evaluate_sq.c.rate, func.count())
            .select_from(evaluate_sq)
            .group_by(evaluate_sq.c.rate)
            .all()
        )
        rate_count_map = {int(rate): int(count) for rate, count in rate_rows if rate is not None}

        total_with_images = (
            self.db.query(func.count(func.distinct(evaluate_sq.c.evaluate_id)))
            .select_from(evaluate_sq)
            .join(EvaluateImage, EvaluateImage.evaluate_id == evaluate_sq.c.evaluate_id)
            .scalar()
            or 0
        )

        sample_content_rows = (
            self.db.query(evaluate_sq.c.content)
            .select_from(evaluate_sq)
            .filter(evaluate_sq.c.content.isnot(None))
            .order_by(evaluate_sq.c.created_at.desc(), evaluate_sq.c.evaluate_id.desc())
            .limit(5)
            .all()
        )
        sample_contents = [str(row[0]).strip() for row in sample_content_rows if str(row[0]).strip()]

        evaluate_id_rows = (
            self.db.query(evaluate_sq.c.evaluate_id)
            .select_from(evaluate_sq)
            .order_by(evaluate_sq.c.created_at.desc(), evaluate_sq.c.evaluate_id.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )
        evaluate_ids = [int(row[0]) for row in evaluate_id_rows]

        evaluates_raw = []
        if evaluate_ids:
            evaluates = (
                self.db.query(Evaluate)
                .options(
                    joinedload(Evaluate.images),
                    joinedload(Evaluate.user),
                    joinedload(Evaluate.order)
                    .joinedload(Order.order_details)
                    .joinedload(OrderDetail.product_detail)
                    .joinedload(ProductDetail.color),
                    joinedload(Evaluate.order)
                    .joinedload(Order.order_details)
                    .joinedload(OrderDetail.product_detail)
                    .joinedload(ProductDetail.size),
                )
                .filter(Evaluate.id.in_(evaluate_ids))
                .all()
            )

            evaluate_map = {e.id: e for e in evaluates}
            ordered = [evaluate_map[eid] for eid in evaluate_ids if eid in evaluate_map]

            for ev in ordered:
                user = getattr(ev, "user", None)
                order = getattr(ev, "order", None)
                order_details_raw = []
                if order:
                    for od in getattr(order, "order_details", []) or []:
                        pd = getattr(od, "product_detail", None)
                        if pd:
                            color = getattr(pd, "color", None)
                            size = getattr(pd, "size", None)
                            order_details_raw.append({
                                "product_detail": {
                                    "id": pd.id,
                                    "product_id": pd.product_id,
                                    "color": {"name": color.name} if color else None,
                                    "size": {"size": size.size} if size else None,
                                },
                            })

                evaluates_raw.append({
                    "id": ev.id,
                    "order_id": ev.order_id,
                    "user_id": ev.user_id,
                    "admin_id": ev.admin_id,
                    "rate": ev.rate,
                    "content": ev.content,
                    "image": ev.image,
                    "admin_reply": ev.admin_reply,
                    "admin_replied_at": ev.admin_replied_at,
                    "created_at": ev.created_at,
                    "updated_at": ev.updated_at,
                    "images": [
                        {"id": img.id, "image_url": img.image_url, "sort_order": img.sort_order}
                        for img in (getattr(ev, "images", []) or [])
                    ],
                    "username": user.username if user else None,
                    "order": {"order_details": order_details_raw} if order else None,
                })

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "product_id": product_id,
            "total": total,
            "avg_rate": float(avg_rate),
            "rate_count_map": rate_count_map,
            "total_with_images": total_with_images,
            "sample_contents": sample_contents,
            "evaluate_ids": evaluate_ids,
            "evaluates_raw": evaluates_raw,
            "total_pages": total_pages,
        }

    def reply_to_evaluate(self, evaluate_id: int, admin_id: int, reply: str) -> Optional[dict]:
        model = (
            self.db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
            .first()
        )
        if not model:
            return None
        model.admin_id = admin_id
        model.admin_reply = reply
        model.admin_replied_at = datetime.now()
        self.db.commit()
        self.db.refresh(model)
        return self._evaluate_to_dict(model)

    def _evaluate_to_dict(self, model) -> dict:
        return {
            "id": model.id,
            "order_id": model.order_id,
            "user_id": model.user_id,
            "admin_id": model.admin_id,
            "rate": model.rate,
            "content": model.content,
            "image": model.image,
            "admin_reply": model.admin_reply,
            "admin_replied_at": model.admin_replied_at,
            "created_at": model.created_at,
            "updated_at": model.updated_at,
            "images": [
                {"id": img.id, "image_url": img.image_url, "sort_order": img.sort_order}
                for img in (getattr(model, "images", []) or [])
            ],
        }
