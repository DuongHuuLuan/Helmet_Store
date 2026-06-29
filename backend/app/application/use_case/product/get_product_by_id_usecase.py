from fastapi import HTTPException, status
from app.domain.repositories.product_repository import ProductRepository


class GetProductByIdUseCase:
    def __init__(self, repo: ProductRepository):
        self.repo = repo

    def execute(self, product_id: int) -> dict:
        result = self.repo.get_by_id_with_details(product_id)
        if not result:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sản phẩm không tồn tại")
        return result
