from fastapi import HTTPException, status

from app.domain.repositories.evaluate_repository import EvaluateRepository


class ReplyEvaluateUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, evaluate_id: int,
                admin_id: int, admin_reply: str) -> dict:
        reply_text = (admin_reply or "").strip()
        if not reply_text:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nội dung phản hồi không được để trống",
            )

        evaluate = self._repo.reply_to_evaluate(
            evaluate_id=evaluate_id,
            admin_id=admin_id,
            reply=reply_text,
        )
        if not evaluate:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Đánh giá không tồn tại",
            )
        return evaluate
