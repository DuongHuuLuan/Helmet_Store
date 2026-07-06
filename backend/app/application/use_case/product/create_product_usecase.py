from fastapi import HTTPException
from app.domain.repositories.product_repository import ProductRepository
from app.domain.entities.product_entity import ProductEntity
from app.application.dto.product_dto import ProductCreate


class CreateProductUseCase:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo

    def execute(self, data: ProductCreate) -> ProductEntity:
        return self.product_repo.create(
            name=data.name,
            category_id=data.category_id,
            description=data.description,
            unit=data.unit.value if hasattr(data.unit, 'value') else str(data.unit),
        )
