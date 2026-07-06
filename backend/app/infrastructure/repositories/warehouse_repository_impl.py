import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.warehouse_mapper import WarehouseMapper
from app.domain.entities.warehouse_entity import WarehouseEntity
from app.domain.repositories.warehouse_repository import WarehouseRepository
from app.infrastructure.database.models.product import Product
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.warehouse import Warehouse, WarehouseDetail


class WarehouseRepositoryImpl(WarehouseRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[WarehouseEntity]:
        model = self.db.query(Warehouse).filter(Warehouse.id == id).first()
        if not model:
            return None
        return WarehouseMapper.to_entity(model)

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        query = self.db.query(Warehouse)
        if keyword:
            query = query.filter(Warehouse.address.ilike(f"%{keyword}%"))

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
        rows = (
            query.outerjoin(WarehouseDetail, WarehouseDetail.warehouse_id == Warehouse.id)
            .with_entities(
                Warehouse,
                func.count(func.distinct(WarehouseDetail.product_id)).label("products_count"),
                func.coalesce(func.sum(WarehouseDetail.quantity), 0).label("total_quantity"),
            )
            .group_by(Warehouse.id)
            .order_by(Warehouse.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        items = []
        for warehouse, products_count, total_quantity in rows:
            setattr(warehouse, "products_count", int(products_count or 0))
            setattr(warehouse, "total_quantity", int(total_quantity or 0))
            setattr(warehouse, "pending_quantity", 0)
            items.append(warehouse)

        last_page = math.ceil(total_count / per_page)
        return {"items": items, "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page}}

    def create(self, data: dict) -> WarehouseEntity:
        model = Warehouse(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return WarehouseMapper.to_entity(model)

    def update(self, id: int, data: dict) -> WarehouseEntity:
        model = self.db.query(Warehouse).filter(Warehouse.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kho không tồn tại")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return WarehouseMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Warehouse).filter(Warehouse.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kho không tồn tại")
        has_stock = (
            self.db.query(WarehouseDetail)
            .filter(WarehouseDetail.warehouse_id == id)
            .first()
        )
        if has_stock:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Không thể xóa kho đang còn hàng")
        self.db.delete(model)
        self.db.commit()

    def get_with_summary(self, id: int) -> Optional[dict]:
        warehouse = self.db.query(Warehouse).filter(Warehouse.id == id).first()
        if not warehouse:
            return None

        summary = (
            self.db.query(
                func.count(func.distinct(WarehouseDetail.product_id)).label("products_count"),
                func.coalesce(func.sum(WarehouseDetail.quantity), 0).label("total_quantity"),
            )
            .filter(WarehouseDetail.warehouse_id == id)
            .first()
        )

        setattr(warehouse, "products_count", int(summary.products_count or 0))
        setattr(warehouse, "total_quantity", int(summary.total_quantity or 0))
        setattr(warehouse, "pending_quantity", 0)
        return warehouse

    def get_detail_list(self, warehouse_id: int, page: int = 1,
                        per_page: Optional[int] = None,
                        keyword: Optional[str] = None,
                        category_id: Optional[int] = None) -> dict:
        warehouse = self.db.query(Warehouse).filter(Warehouse.id == warehouse_id).first()
        if not warehouse:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kho không tồn tại",
            )

        summary = (
            self.db.query(
                func.count(func.distinct(WarehouseDetail.product_id)).label("products_count"),
                func.coalesce(func.sum(WarehouseDetail.quantity), 0).label("total_quantity"),
            )
            .filter(WarehouseDetail.warehouse_id == warehouse_id)
            .first()
        )
        setattr(warehouse, "products_count", int(summary.products_count or 0))
        setattr(warehouse, "total_quantity", int(summary.total_quantity or 0))
        setattr(warehouse, "pending_quantity", 0)

        detail_query = self.db.query(WarehouseDetail).filter(
            WarehouseDetail.warehouse_id == warehouse_id
        )
        if keyword or category_id is not None:
            detail_query = detail_query.join(
                Product, WarehouseDetail.product_id == Product.id
            )
        if keyword:
            detail_query = detail_query.filter(Product.name.ilike(f"%{keyword}%"))
        if category_id is not None:
            detail_query = detail_query.filter(Product.category_id == category_id)

        total_count = detail_query.count()
        if total_count == 0:
            return {
                "warehouse": warehouse,
                "items": [],
                "meta": {"total": 0, "current_page": 1, "per_page": per_page or 0, "last_page": 1},
            }

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            per_page = max(per_page, 1)
            page = max(page, 1)

        skip = (page - 1) * per_page
        rows = (
            detail_query.options(
                joinedload(WarehouseDetail.product).joinedload(Product.category),
                joinedload(WarehouseDetail.product).joinedload(Product.product_images),
                joinedload(WarehouseDetail.color),
                joinedload(WarehouseDetail.size),
            )
            .order_by(WarehouseDetail.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        items = []
        for row in rows:
            product_detail = (
                self.db.query(ProductDetail)
                .filter(
                    ProductDetail.product_id == row.product_id,
                    ProductDetail.color_id == row.color_id,
                    ProductDetail.size_id == row.size_id,
                )
                .first()
            )
            items.append({
                "id": row.id,
                "product": row.product,
                "color": row.color,
                "size": row.size,
                "quantity": row.quantity,
                "product_detail_id": product_detail.id if product_detail else None,
                "is_active": bool(product_detail.is_active) if product_detail else False,
            })

        last_page = (total_count + per_page - 1) // per_page
        return {
            "warehouse": warehouse,
            "items": items,
            "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page},
        }

    def get_total_stock(self, product_id: int, size_id: int, color_id: int) -> int:
        result = (
            self.db.query(func.coalesce(func.sum(WarehouseDetail.quantity), 0))
            .filter(
                WarehouseDetail.product_id == product_id,
                WarehouseDetail.size_id == size_id,
                WarehouseDetail.color_id == color_id,
            )
            .scalar()
        )
        return int(result)

    def get_total_stock_for_detail(self, product_detail) -> int:
        if not product_detail:
            return 0
        return self.get_total_stock(
            product_id=product_detail.product_id,
            size_id=product_detail.size_id,
            color_id=product_detail.color_id,
        )

    def decrease_stock(self, product_id: int, color_id: int, size_id: int, quantity: int) -> None:
        if quantity <= 0:
            return
        stocks = (
            self.db.query(WarehouseDetail)
            .filter(
                WarehouseDetail.product_id == product_id,
                WarehouseDetail.color_id == color_id,
                WarehouseDetail.size_id == size_id,
            )
            .order_by(WarehouseDetail.warehouse_id.asc())
            .all()
        )
        remaining = quantity
        for stock in stocks:
            if remaining <= 0:
                break
            if stock.quantity >= remaining:
                stock.quantity -= remaining
                remaining = 0
            else:
                remaining -= stock.quantity
                stock.quantity = 0
        if remaining > 0:
            raise HTTPException(status_code=400, detail="Không đủ hàng trong kho")

    def increase_stock(self, product_id: int, color_id: int, size_id: int, quantity: int) -> None:
        if quantity <= 0:
            return
        stock = (
            self.db.query(WarehouseDetail)
            .filter(
                WarehouseDetail.product_id == product_id,
                WarehouseDetail.color_id == color_id,
                WarehouseDetail.size_id == size_id,
            )
            .order_by(WarehouseDetail.warehouse_id.asc())
            .first()
        )
        if stock:
            stock.quantity += quantity
            return
        warehouse = self.db.query(Warehouse).order_by(Warehouse.id.asc()).first()
        if not warehouse:
            raise HTTPException(status_code=400, detail="Không còn kho để hoàn hàng")
        new_stock = WarehouseDetail(
            warehouse_id=warehouse.id,
            product_id=product_id,
            color_id=color_id,
            size_id=size_id,
            quantity=quantity,
        )
        self.db.add(new_stock)
