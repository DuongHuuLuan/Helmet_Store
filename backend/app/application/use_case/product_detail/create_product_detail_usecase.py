from app.domain.repositories.product_detail_repository import ProductDetailRepository
from app.domain.entities.product_detail_entity import ProductDetailEntity
from app.application.dto.product_detail_dto import ProductDetailCreate


class CreateProductDetailUseCase:
    def __init__(self, detail_repo: ProductDetailRepository):
        self.detail_repo = detail_repo

    def execute(self, product_id: int, data: ProductDetailCreate) -> ProductDetailEntity:
        existing = self.detail_repo.get_by_product_and_color_size(
            product_id=product_id,
            color_id=data.color_id,
            size_id=data.size_id,
        )
        if existing:
            return self.detail_repo.update(existing.id, {
                "price": data.price,
                "is_active": data.is_active,
            })
        return self.detail_repo.create(
            product_id=product_id,
            color_id=data.color_id,
            size_id=data.size_id,
            price=data.price,
            is_active=data.is_active,
        )
