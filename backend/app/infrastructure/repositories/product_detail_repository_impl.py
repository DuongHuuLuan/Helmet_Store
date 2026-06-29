from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.product_detail_mapper import ProductDetailMapper
from app.domain.entities.product_detail_entity import ProductDetailEntity
from app.domain.repositories.product_detail_repository import ProductDetailRepository
from app.infrastructure.database.models.product_detail import ProductDetail


class ProductDetailRepositoryImpl(ProductDetailRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[ProductDetailEntity]:
        model = self.db.query(ProductDetail).filter(ProductDetail.id == id).first()
        if not model:
            return None
        return ProductDetailMapper.to_entity(model)

    def get_by_product_and_color_size(self, product_id: int, color_id: int,
                                      size_id: int) -> Optional[ProductDetailEntity]:
        model = (
            self.db.query(ProductDetail)
            .filter(
                ProductDetail.product_id == product_id,
                ProductDetail.color_id == color_id,
                ProductDetail.size_id == size_id,
            )
            .first()
        )
        if not model:
            return None
        return ProductDetailMapper.to_entity(model)

    def create(self, product_id: int, color_id: int, size_id: int,
               price: int, is_active: bool = True) -> ProductDetailEntity:
        model = ProductDetail(
            product_id=product_id,
            color_id=color_id,
            size_id=size_id,
            price=price,
            is_active=is_active,
        )
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ProductDetailMapper.to_entity(model)

    def update(self, id: int, data: dict) -> ProductDetailEntity:
        model = self.db.query(ProductDetail).filter(ProductDetail.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy biến thể sản phẩm")
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ProductDetailMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(ProductDetail).filter(ProductDetail.id == id).first()
        if not model:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy biến thể sản phẩm cần xóa")
        self.db.delete(model)
        self.db.commit()
