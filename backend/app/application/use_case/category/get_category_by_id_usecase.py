from app.domain.repositories.category_repository import CategoryRepository


class GetCategoryByIdUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(self, id: int) -> dict:
        entity = self.repo.get_by_id(id)
        count = self.repo.get_product_count(id)
        return {
            "id": entity.id,
            "name": entity.name,
            "products_count": count,
            "created_at": entity.created_at,
        }
