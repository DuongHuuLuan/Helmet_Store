from fastapi import HTTPException, status

from app.domain.repositories.category_repository import CategoryRepository


class CreateCategoryUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(self, name: str) -> dict:
        if self.repo.exists_by_name(name):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Danh mục đã tồn tại",
            )
        entity = self.repo.create(name=name)
        return {
            "id": entity.id,
            "name": entity.name,
            "created_at": entity.created_at,
        }
