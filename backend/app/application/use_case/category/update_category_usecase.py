from fastapi import HTTPException, status

from app.domain.repositories.category_repository import CategoryRepository


class UpdateCategoryUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(self, id: int, name: str) -> dict:
        entity = self.repo.get_by_id(id)
        if name != entity.name and self.repo.exists_by_name(name):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tên danh mục đã tồn tại",
            )
        entity = self.repo.update(id=id, name=name)
        return {
            "id": entity.id,
            "name": entity.name,
            "created_at": entity.created_at,
        }
