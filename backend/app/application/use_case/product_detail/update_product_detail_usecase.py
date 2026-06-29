from app.domain.repositories.product_detail_repository import ProductDetailRepository
from app.domain.entities.product_detail_entity import ProductDetailEntity


class UpdateProductDetailUseCase:
    def __init__(self, detail_repo: ProductDetailRepository):
        self.detail_repo = detail_repo

    def execute(self, detail_id: int, data: dict) -> ProductDetailEntity:
        return self.detail_repo.update(detail_id, data)
