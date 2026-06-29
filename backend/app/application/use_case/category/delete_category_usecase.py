from fastapi import HTTPException, status

from app.domain.repositories.category_repository import CategoryRepository


class DeleteCategoryUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(self, id: int) -> None:
        if self.repo.is_used_in_products(id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không thể xóa danh mục này vì vẫn còn sản phẩm bên trong.",
            )
        self.repo.delete(id)
