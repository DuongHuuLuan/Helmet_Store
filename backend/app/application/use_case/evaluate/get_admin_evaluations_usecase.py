from typing import Optional

from app.domain.repositories.evaluate_repository import EvaluateRepository


class GetAdminEvaluationsUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, page: int = 1, per_page: int = 8,
                has_reply: Optional[bool] = None,
                order_id: Optional[int] = None) -> dict:
        return self._repo.get_admin_evaluations_paginated(
            page=page,
            per_page=per_page,
            has_reply=has_reply,
            order_id=order_id,
        )
