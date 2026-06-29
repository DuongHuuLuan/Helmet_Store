from app.domain.repositories.product_repository import ProductRepository


class EnsureDeleteUseCase:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo

    def execute(self, product_id: int):
        self.product_repo.ensure_can_delete(product_id)
