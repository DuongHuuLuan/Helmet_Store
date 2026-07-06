import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.product_mapper import ProductMapper
from app.domain.entities.product_entity import ProductEntity
from app.domain.repositories.product_repository import ProductRepository
from app.infrastructure.database.models.product import Product, UnitEnum
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.order import OrderDetail
from app.infrastructure.database.models.receipt import ReceiptDetail


class ProductRepositoryImpl(ProductRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[ProductEntity]:
        model = self.db.query(Product).filter(Product.id == id).first()
        if not model:
            return None
        return ProductMapper.to_entity(model)

    def create(self, name: str, category_id: int, description: Optional[str] = None,
               unit: str = "Chiếc") -> ProductEntity:
        try:
            unit_enum = UnitEnum(unit)
        except ValueError:
            unit_enum = UnitEnum.CHIEC
        model = Product(name=name, category_id=category_id, description=description, unit=unit_enum)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ProductMapper.to_entity(model)

    def update(self, id: int, data: dict) -> ProductEntity:
        model = self.db.query(Product).filter(Product.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sản phẩm không tồn tại")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ProductMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Product).filter(Product.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sản phẩm không tồn tại")
        self.db.delete(model)
        self.db.commit()

    def exists_by_id(self, id: int) -> bool:
        return self.db.query(Product.id).filter(Product.id == id).first() is not None

    def ensure_can_delete(self, id: int) -> None:
        if not self.exists_by_id(id):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sản phẩm không tồn tại")

        receipt_exists = (
            self.db.query(ReceiptDetail.product_id)
            .filter(ReceiptDetail.product_id == id)
            .first()
        )
        if receipt_exists:
            raise HTTPException(status_code=400, detail="Không thể xóa: sản phẩm đã tạo phiếu nhập")

        order_exists = (
            self.db.query(ProductDetail.id)
            .join(OrderDetail, OrderDetail.product_detail_id == ProductDetail.id)
            .filter(ProductDetail.product_id == id)
            .first()
        )
        if order_exists:
            raise HTTPException(status_code=400, detail="Không thể xóa: sản phẩm đã được bán")

    def count_all(self) -> int:
        return self.db.query(func.count(Product.id)).scalar() or 0

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, category_id: Optional[int] = None) -> dict:
        from sqlalchemy.orm import joinedload

        query = self.db.query(Product).options(
            joinedload(Product.category),
            joinedload(Product.product_images),
            joinedload(Product.product_details),
        )

        if category_id is not None:
            query = query.filter(Product.category_id == category_id)
        if keyword:
            query = query.filter(Product.name.ilike(f"%{keyword}%"))

        total_count = query.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        models = query.order_by(Product.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)

        return {
            "items": [ProductMapper.to_entity(m) for m in models],
            "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page},
        }

    _VIEW_IMAGE_ORDER = {
        "front": 0, "front_right": 1, "right": 2,
        "back": 3, "left": 4, "front_left": 5,
    }

    def _check_can_delete(self, product_id: int) -> tuple[bool, str | None]:
        if self.db.query(ReceiptDetail.id).filter(ReceiptDetail.product_id == product_id).first():
            return False, "Không thể xóa: sản phẩm đã tạo phiếu nhập"
        if (
            self.db.query(ProductDetail.id)
            .join(OrderDetail, OrderDetail.product_detail_id == ProductDetail.id)
            .filter(ProductDetail.product_id == product_id)
            .first()
        ):
            return False, "Không thể xóa: sản phẩm đã được bán"
        return True, None

    def _build_images(self, images):
        return [
            {
                "id": img.id, "product_id": img.product_id,
                "url": img.url, "public_id": img.public_id,
                "color_id": img.color_id, "view_image_key": img.view_image_key,
                "created_at": img.created_at.isoformat() if img.created_at else None,
            }
            for img in images
        ]

    def _build_design_views(self, images):
        sorted_imgs = sorted(
            [img for img in images if str(getattr(img, "view_image_key", "") or "").strip()],
            key=lambda img: (
                img.color_id is None,
                img.color_id or 0,
                self._VIEW_IMAGE_ORDER.get(str(img.view_image_key or "").strip(), 999),
                img.id or 0,
            ),
        )
        return [
            {
                "id": img.id, "product_id": img.product_id,
                "url": img.url, "public_id": img.public_id,
                "color_id": img.color_id, "view_image_key": img.view_image_key,
                "created_at": img.created_at.isoformat() if img.created_at else None,
            }
            for img in sorted_imgs
        ]

    def _build_details(self, details):
        return [
            {
                "id": pd.id,
                "color": {"id": pd.color.id, "name": pd.color.name, "hexcode": pd.color.hexcode},
                "size": {"id": pd.size.id, "size": pd.size.size},
                "price": pd.price,
                "is_active": pd.is_active,
            }
            for pd in details
        ]

    def _build_product_response(self, model) -> dict:
        can_delete, block_reason = self._check_can_delete(model.id)
        return {
            "id": model.id,
            "name": model.name,
            "description": model.description,
            "unit": model.unit.value if hasattr(model.unit, 'value') else model.unit,
            "category_id": model.category_id,
            "category": {
                "id": model.category.id,
                "name": model.category.name,
                "created_at": model.category.created_at.isoformat() if model.category.created_at else None,
            } if model.category else None,
            "product_images": self._build_images(model.product_images or []),
            "design_views": self._build_design_views(model.product_images or []),
            "product_details": self._build_details(model.product_details or []),
            "can_delete": can_delete,
            "delete_block_reason": block_reason,
            "created_at": model.created_at.isoformat() if model.created_at else None,
            "updated_at": model.updated_at.isoformat() if model.updated_at else None,
        }

    def get_by_id_with_details(self, id: int) -> Optional[dict]:
        from sqlalchemy.orm import joinedload
        model = (
            self.db.query(Product)
            .options(
                joinedload(Product.category),
                joinedload(Product.product_images),
                joinedload(Product.product_details)
                .joinedload(ProductDetail.color),
                joinedload(Product.product_details)
                .joinedload(ProductDetail.size),
            )
            .filter(Product.id == id)
            .first()
        )
        if not model:
            return None
        return self._build_product_response(model)

    def get_all_with_details(self, page: int = 1, per_page: Optional[int] = None,
                              keyword: Optional[str] = None, category_id: Optional[int] = None) -> dict:
        from sqlalchemy.orm import joinedload

        query = self.db.query(Product).options(
            joinedload(Product.category),
            joinedload(Product.product_images),
            joinedload(Product.product_details)
            .joinedload(ProductDetail.color),
            joinedload(Product.product_details)
            .joinedload(ProductDetail.size),
        )

        if category_id is not None:
            query = query.filter(Product.category_id == category_id)
        if keyword:
            query = query.filter(Product.name.ilike(f"%{keyword}%"))

        total_count = query.count()
        if total_count == 0:
            return {"items": [], "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1}}

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        models = query.order_by(Product.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)

        items = [self._build_product_response(m) for m in models]
        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}
