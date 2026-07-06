import math

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.category_mapper import CategoryMapper
from app.domain.entities.category_entity import CategoryEntity
from app.domain.repositories.category_repository import CategoryRepository
from app.infrastructure.database.models.category import Category
from app.infrastructure.database.models.product import Product


class CategoryRepositoryImpl(CategoryRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> list[CategoryEntity]:
        models = self.db.query(Category).order_by(Category.id.asc()).all()
        return [CategoryMapper.to_entity(m) for m in models]

    def get_all_paginated(
        self,
        page: int = 1,
        per_page: int | None = None,
        keyword: str | None = None,
    ) -> tuple[list[tuple[CategoryEntity, int]], int]:
        query = self.db.query(Category)
        if keyword:
            query = query.filter(Category.name.ilike(f"%{keyword}%"))

        total_count = query.count()

        if total_count == 0:
            return [], 0

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        rows = (
            query.outerjoin(Product, Product.category_id == Category.id)
            .with_entities(Category, func.count(Product.id).label("products_count"))
            .group_by(Category.id)
            .order_by(Category.id.asc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        result = [
            (CategoryMapper.to_entity(category), count)
            for category, count in rows
        ]
        return result, total_count

    def get_by_id(self, id: int) -> CategoryEntity:
        model = self.db.query(Category).filter(Category.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục",
            )
        return CategoryMapper.to_entity(model)

    def get_product_count(self, id: int) -> int:
        return (
            self.db.query(func.count(Product.id))
            .filter(Product.category_id == id)
            .scalar()
            or 0
        )

    def create(self, name: str) -> CategoryEntity:
        model = Category(name=name)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return CategoryMapper.to_entity(model)

    def update(self, id: int, name: str) -> CategoryEntity:
        model = self.db.query(Category).filter(Category.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục",
            )
        model.name = name
        self.db.commit()
        self.db.refresh(model)
        return CategoryMapper.to_entity(model)

    def delete(self, id: int) -> None:
        model = self.db.query(Category).filter(Category.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục",
            )
        self.db.delete(model)
        self.db.commit()

    def exists_by_name(self, name: str) -> bool:
        return (
            self.db.query(Category).filter(Category.name == name).first()
            is not None
        )

    def is_used_in_products(self, id: int) -> bool:
        return (
            self.db.query(Product)
            .filter(Product.category_id == id)
            .first()
            is not None
        )

    def get_products_by_category(self, id: int) -> list:
        model = self.db.query(Category).filter(Category.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy danh mục",
            )
        return model.products
