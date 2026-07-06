from fastapi import HTTPException, status

from app.domain.repositories.sticker_repository import StickerRepository


class DeleteStickerUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, sticker_id: int) -> dict:
        entity = self.repo.get_by_id(sticker_id)
        if not entity or entity.owner_user_id is not None:
            raise HTTPException(status_code=404, detail="System sticker not found")

        usage = self.repo.count_usage(sticker_id)
        if usage > 0:
            raise HTTPException(
                status_code=400,
                detail="Không thể xóa sticker đã được người dùng sử dụng trong thiết kế",
            )

        self.repo.delete(sticker_id)
        return {"message": "Xóa sticker thành công"}
