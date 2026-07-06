from app.domain.repositories.evaluate_repository import EvaluateRepository


class GetMyEvaluationsUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, user_id: int,
                page: int = 1, per_page: int = 8) -> dict:
        return self._repo.get_my_evaluations_paginated(
            user_id=user_id,
            page=page,
            per_page=per_page,
        )
