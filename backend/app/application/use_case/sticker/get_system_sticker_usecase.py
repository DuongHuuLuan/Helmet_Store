from fastapi import HTTPException, status

from app.domain.repositories.sticker_repository import StickerRepository


class GetSystemStickerUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, sticker_id: int) -> dict:
        result = self.repo.get_system_by_id_with_details(sticker_id)
        if not result:
            raise HTTPException(status_code=404, detail="System sticker not found")
        return result
