from app.domain.entities.color_entity import ColorEntity
from app.domain.repositories.color_repository import ColorRepository


class UpdateColorUseCase:
    def __init__(self, repo: ColorRepository):
        self.repo = repo

    def execute(self, id: int, name: str, hexcode: str) -> ColorEntity:
        return self.repo.update(id=id, name=name, hexcode=hexcode)
