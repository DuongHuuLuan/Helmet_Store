from app.domain.repositories.category_repository import CategoryRepository


class GetCategoryProductsUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(self, id: int) -> list:
        return self.repo.get_products_by_category(id)
