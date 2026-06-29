from app.domain.repositories.product_repository import ProductRepository
from app.domain.entities.product_entity import ProductEntity


class UpdateProductUseCase:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo

    def execute(self, product_id: int, data: dict) -> ProductEntity:
        return self.product_repo.update(product_id, data)
