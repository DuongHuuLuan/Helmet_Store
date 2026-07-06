import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.receipt_mapper import ReceiptMapper
from app.domain.entities.receipt_entity import ReceiptEntity
from app.domain.repositories.receipt_repository import ReceiptRepository
from app.infrastructure.database.models.receipt import Receipt, ReceiptDetail, ReceiptStatus
from app.infrastructure.database.models.warehouse import Warehouse, WarehouseDetail
from app.infrastructure.database.models.distributor import Distributor
from app.infrastructure.database.models.product import Product
from app.infrastructure.database.models.product_detail import ProductDetail
from app.infrastructure.database.models.category import Category


class ReceiptRepositoryImpl(ReceiptRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[ReceiptEntity]:
        model = self.db.query(Receipt).filter(Receipt.id == id).first()
        if not model:
            return None
        return ReceiptMapper.to_entity(model)

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        query = self.db.query(Receipt)
        if keyword:
            query = (
                query.join(Warehouse, Receipt.warehouse_id == Warehouse.id)
                .join(Distributor, Receipt.distributor_id == Distributor.id)
                .filter(
                    or_(
                        Warehouse.address.ilike(f"%{keyword}%"),
                        Distributor.name.ilike(f"%{keyword}%"),
                    )
                )
            )

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
        models = (
            query.options(
                joinedload(Receipt.warehouse),
                joinedload(Receipt.distributor),
            )
            .order_by(Receipt.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        receipt_ids = [r.id for r in models]
        counts = {}
        if receipt_ids:
            rows = (
                self.db.query(ReceiptDetail.receipt_id, func.count(ReceiptDetail.id))
                .filter(ReceiptDetail.receipt_id.in_(receipt_ids))
                .group_by(ReceiptDetail.receipt_id)
                .all()
            )
            counts = {rid: int(cnt) for rid, cnt in rows}

        for r in models:
            setattr(r, "items_count", counts.get(r.id, 0))

        last_page = math.ceil(total_count / per_page)
        return {
            "items": models,
            "meta": {"total": total_count, "current_page": page, "per_page": per_page, "last_page": last_page},
        }

    def create(self, data: dict) -> ReceiptEntity:
        model = Receipt(**data)
        self.db.add(model)
        self.db.flush()
        return ReceiptMapper.to_entity(model)

    def update(self, id: int, data: dict) -> ReceiptEntity:
        model = self.db.query(Receipt).filter(Receipt.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phiếu nhập")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ReceiptMapper.to_entity(model)

    def get_by_id_with_details(self, id: int) -> Optional[dict]:
        model = (
            self.db.query(Receipt)
            .options(
                joinedload(Receipt.warehouse),
                joinedload(Receipt.distributor),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.category),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_images),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_details)
                    .joinedload(ProductDetail.color),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_details)
                    .joinedload(ProductDetail.size),
            )
            .filter(Receipt.id == id)
            .first()
        )
        if not model:
            return None
        return model

    def create_with_details(self, data: dict, details_data: list[dict]) -> dict:
        model = Receipt(**data)
        self.db.add(model)
        self.db.flush()

        for detail_in in details_data:
            detail = ReceiptDetail(
                receipt_id=model.id,
                product_id=detail_in["product_id"],
                color_id=detail_in.get("color_id"),
                size_id=detail_in.get("size_id"),
                quantity=detail_in["quantity"],
                purchase_price=detail_in["purchase_price"],
            )
            self.db.add(detail)

        self.db.commit()
        self.db.refresh(model)
        result = self.get_by_id_with_details(model.id)
        return result

    def confirm_receipt(self, id: int) -> dict:
        model = (
            self.db.query(Receipt)
            .options(
                joinedload(Receipt.warehouse),
                joinedload(Receipt.distributor),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.category),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_images),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_details),
                joinedload(Receipt.details).joinedload(ReceiptDetail.color),
                joinedload(Receipt.details).joinedload(ReceiptDetail.size),
            )
            .filter(Receipt.id == id)
            .first()
        )
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phiếu nhập")
        if model.status != ReceiptStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Chỉ có thể xác nhận phiếu nhập đang chờ xử lý")

        for item in model.details:
            stock = (
                self.db.query(WarehouseDetail)
                .filter(
                    WarehouseDetail.warehouse_id == model.warehouse_id,
                    WarehouseDetail.product_id == item.product_id,
                    WarehouseDetail.color_id == item.color_id,
                    WarehouseDetail.size_id == item.size_id,
                )
                .first()
            )
            if stock:
                stock.quantity += item.quantity
            else:
                new_stock = WarehouseDetail(
                    warehouse_id=model.warehouse_id,
                    product_id=item.product_id,
                    color_id=item.color_id,
                    size_id=item.size_id,
                    quantity=item.quantity,
                )
                self.db.add(new_stock)

        model.status = ReceiptStatus.COMPLETED
        self.db.commit()
        return self.get_by_id_with_details(model.id)

    def cancel_receipt(self, id: int) -> dict:
        model = (
            self.db.query(Receipt)
            .options(
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_details)
                    .joinedload(ProductDetail.color),
                joinedload(Receipt.details)
                    .joinedload(ReceiptDetail.product)
                    .joinedload(Product.product_details)
                    .joinedload(ProductDetail.size),
            )
            .filter(Receipt.id == id)
            .first()
        )
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy phiếu nhập")
        if model.status != ReceiptStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Chỉ có thể hủy phiếu nhập đang chờ xử lý")

        model.status = ReceiptStatus.CANCELLED
        self.db.commit()
        result = self.get_by_id_with_details(model.id)
        return result
