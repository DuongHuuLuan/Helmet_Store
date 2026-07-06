from fastapi import HTTPException, status
from app.domain.repositories.discount_repository import DiscountRepository


class GetDiscountByIdUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, discount_id: int) -> dict:
        result = self.repo.get_by_id_with_details(discount_id)
        if not result:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy khuyến mãi")
        return result
