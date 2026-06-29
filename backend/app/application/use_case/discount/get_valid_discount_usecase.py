from fastapi import HTTPException, status
from app.domain.repositories.discount_repository import DiscountRepository


class GetValidDiscountUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, code_name: str) -> dict:
        result = self.repo.get_valid_by_name(code_name)
        if not result:
            raise HTTPException(status_code=404, detail="Mã giảm giá không tồn tại, đã hết hạn hoặc chưa đến thời gian áp dụng")
        return result
