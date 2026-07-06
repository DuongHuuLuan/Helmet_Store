from typing import Optional

from app.domain.repositories.product_repository import ProductRepository


class GetProductsUseCase:
    def __init__(self, repo: ProductRepository):
        self.repo = repo

    def execute(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, category_id: Optional[int] = None) -> dict:
        return self.repo.get_all_with_details(
            page=page, per_page=per_page,
            keyword=keyword, category_id=category_id,
        )
