from fastapi import HTTPException, status

from app.domain.repositories.sticker_repository import StickerRepository


class GetAdminStickerUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, sticker_id: int) -> dict:
        result = self.repo.get_by_id_with_details(sticker_id)
        if not result:
            raise HTTPException(status_code=404, detail="Sticker not found")
        return result
