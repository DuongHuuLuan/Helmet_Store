from typing import Optional
from app.domain.repositories.discount_repository import DiscountRepository


class GetDiscountsUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None) -> dict:
        return self.repo.get_all(page=page, per_page=per_page, keyword=keyword)
