from app.domain.repositories.product_repository import ProductRepository


class DeleteProductUseCase:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo

    def execute(self, product_id: int, skip_validate: bool = False) -> dict:
        if not skip_validate:
            self.product_repo.ensure_can_delete(product_id)
        self.product_repo.delete(product_id)
        return {"message": "Đã xóa sản phẩm thành công"}
