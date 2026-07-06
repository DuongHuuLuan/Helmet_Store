from typing import Optional
from app.domain.repositories.user_repository import UserRepository


class GetUsersUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def execute(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, role: Optional[str] = None) -> dict:
        return self.user_repo.get_all(
            page=page,
            per_page=per_page,
            keyword=keyword,
            role=role,
        )
