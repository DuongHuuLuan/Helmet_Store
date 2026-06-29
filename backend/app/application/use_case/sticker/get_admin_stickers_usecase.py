from typing import Optional

from fastapi import HTTPException, status

from app.domain.repositories.sticker_repository import StickerRepository


class GetAdminStickersUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, page: int = 1,
                per_page: Optional[int] = None,
                keyword: Optional[str] = None,
                category: Optional[str] = None,
                scope: Optional[str] = "system") -> dict:
        normalized_scope = (scope or "system").strip().lower()
        if normalized_scope not in {"system", "user"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phạm vi sticker không hợp lệ",
            )
        return self.repo.get_all(
            page=page,
            per_page=per_page,
            keyword=keyword,
            category=category,
            scope=normalized_scope,
        )
