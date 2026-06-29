from fastapi import HTTPException, status

from app.domain.repositories.evaluate_repository import EvaluateRepository


class GetEvaluateByOrderUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, order_id: int,
                user_id: int, is_admin: bool) -> dict:
        evaluate = self._repo.get_evaluate_by_order_with_details(
            order_id=order_id,
            user_id=user_id,
            is_admin=is_admin,
        )
        if not evaluate:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Đánh giá không tồn tại",
            )
        return evaluate
