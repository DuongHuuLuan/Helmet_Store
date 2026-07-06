from fastapi import HTTPException, status

from app.domain.repositories.size_repository import SizeRepository


class DeleteSizeUseCase:
    def __init__(self, repo: SizeRepository):
        self.repo = repo

    def execute(self, id: int) -> None:
        if self.repo.is_used_in_product_detail(id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Size đang được sử dụng",
            )
        self.repo.delete(id)
