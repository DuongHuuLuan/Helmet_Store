import math
from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session
from app.models.discount import Discount, DiscountStatus, OrderDiscount
from typing import Dict, Iterable, List, Optional
from datetime import datetime
from app.services.base import BaseService

class DiscountService(BaseService):
    @staticmethod
    def _get_blocked_discount_ids(db: Session, discount_ids: List[int]) -> set[int]:
        if not discount_ids:
            return set()

        rows = (
            db.query(OrderDiscount.discount_id)
            .filter(OrderDiscount.discount_id.in_(discount_ids))
            .distinct()
            .all()
        )
        return {row[0] for row in rows if row[0] is not None}

    @staticmethod
    def _attach_delete_permissions(db: Session, discounts: List[Discount]) -> None:
        discount_ids = [item.id for item in discounts if getattr(item, "id", None) is not None]
        blocked_ids = DiscountService._get_blocked_discount_ids(db, discount_ids)

        for discount in discounts:
            setattr(discount, "can_delete", discount.id not in blocked_ids)

    @staticmethod
    def ensure_discount_can_delete(db: Session, discount_id: int) -> Discount:
        discount = DiscountService.get_or_404(db, Discount, discount_id, "Không tìm thấy khuyến mãi")
        blocked_ids = DiscountService._get_blocked_discount_ids(db, [discount_id])

        if discount_id in blocked_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không thể xóa khuyến mãi đã áp dụng cho đơn hàng.",
            )

        setattr(discount, "can_delete", True)
        return discount

    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None
    ):
        query = db.query(Discount)

        if keyword:
            like = f"%{keyword}%"
            query = query.filter(or_(Discount.name.ilike(like), Discount.description.ilike(like)))
        
        total_count = query.count()

        if total_count == 0:
            return {
                "items": [],
                "meta": {
                    "total": 0,
                    "current_page": 1,
                    "per_page": per_page or 0,
                    "last_page": 1,
                },
            }
        
        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1
        
        skip = (page - 1) * per_page
        items = (
            query.order_by(Discount.id.desc()).offset(skip).limit(per_page).all()
        )
        DiscountService._attach_delete_permissions(db, items)
        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }
    
    @staticmethod
    def get_id(db: Session, discount_id: int):
        discount = DiscountService.get_or_404(db, Discount, discount_id, "Không tìm thấy khuyến mãi")
        DiscountService._attach_delete_permissions(db, [discount])
        return discount

    @staticmethod
    def create(db: Session, discount_in):
        new_discount = Discount(
            **discount_in.model_dump(),
            status=DiscountStatus.ACTIVE,
        )
        db.add(new_discount)
        db.commit()
        db.refresh(new_discount)
        return new_discount

    @staticmethod
    def update(db: Session, discount_id: int, discount_in):
        discount = DiscountService.get_id(db, discount_id)
        update_data = discount_in.model_dump(exclude_unset=True)

        status_value = update_data.pop("status", None)
        if status_value is not None:
            if isinstance(status_value, DiscountStatus):
                discount.status = status_value
            else:
                try:
                    discount.status = DiscountStatus(status_value)
                except ValueError as exc:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Trạng thái không hợp lệ",
                    ) from exc

        for key, value in update_data.items():
            setattr(discount, key, value)

        db.commit()
        db.refresh(discount)
        return discount

    @staticmethod
    def delete(db: Session, discount_id: int):
        discount = DiscountService.ensure_discount_can_delete(db, discount_id)
        db.delete(discount)
        db.commit()
        return {"message": "Xóa khuyến mãi thành công"}

    @staticmethod
    def get_valid_discount(db: Session, code_name: str):
        now = datetime.now()
        return db.query(Discount).filter(
            Discount.name.ilike((code_name or "").strip()),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <=  now,
            Discount.end_at >= now
        ).first()

    @staticmethod
    def get_valid_discounts_by_category_ids(
        db: Session,
        category_ids: Iterable[int],
    ) -> Dict[int, Discount]:
        category_ids = list(category_ids)
        if not category_ids:
            return {}

        now = datetime.now()
        discounts = db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).order_by(
            Discount.category_id,
            Discount.start_at.desc(),
            Discount.id.desc(),
        ).all()

        result: Dict[int, Discount] = {}
        for discount in discounts:
            if discount.category_id not in result:
                result[discount.category_id] = discount
        return result
## hàm lấy cả sticker còn hạn dựa trên danh mục
    @staticmethod
    def list_valid_discounts_by_category_ids(
        db: Session,
        category_ids: Iterable[int],
        limit: Optional[int] = None,
    ) -> List[Discount]:
        normalized_ids = list(
            dict.fromkeys(
                int(category_id)
                for category_id in category_ids
                if isinstance(category_id, int)
            )
        )
        if not normalized_ids:
            return []

        now = datetime.now()
        query = (
            db.query(Discount)
            .filter(
                Discount.category_id.in_(normalized_ids),
                Discount.status == DiscountStatus.ACTIVE,
                Discount.start_at <= now,
                Discount.end_at >= now,
            )
            .order_by(
                Discount.percent.desc(),
                Discount.end_at.asc(),
                Discount.id.desc(),
            )
        )

        if isinstance(limit, int) and limit > 0:
            query = query.limit(limit)

        return query.all()


    @staticmethod
    def get_available_discouts_for_cart(db: Session, category_ids: List[int]):
        now = datetime.now()

        return db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now
        ).all()

    @staticmethod
    def get_active_discounts(
        db: Session,
        limit: Optional[int] = None,
        keyword: Optional[str] = None,
    ) -> List[Discount]:
        now = datetime.now()
        query = db.query(Discount).filter(
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
        return query.all()
        
