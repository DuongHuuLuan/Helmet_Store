from app.domain.repositories.discount_repository import DiscountRepository


class GetAvailableDiscountsForCartUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, category_ids: list[int]) -> list:
        return self.repo.get_valid_for_categories(category_ids)
