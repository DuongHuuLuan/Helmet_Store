from typing import Optional

from app.domain.entities.sticker_entity import StickerEntity
from app.domain.repositories.sticker_repository import StickerRepository


class GetStickerCatalogUseCase:
    def __init__(self, repo: StickerRepository):
        self.repo = repo

    def execute(self, user_id: Optional[int] = None) -> list[StickerEntity]:
        return self.repo.get_catalog(user_id)
