from app.domain.repositories.discount_repository import DiscountRepository


class GetDiscountsByCategoryIdsUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, category_ids: list[int]) -> dict:
        return self.repo.get_grouped_by_category_ids(category_ids)
