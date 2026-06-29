from app.domain.repositories.discount_repository import DiscountRepository


class DeleteDiscountUseCase:
    def __init__(self, repo: DiscountRepository):
        self.repo = repo

    def execute(self, discount_id: int) -> dict:
        self.repo.ensure_can_delete(discount_id)
        self.repo.delete(discount_id)
        return {"message": "Xóa khuyến mãi thành công"}
