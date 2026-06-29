from app.domain.entities.color_entity import ColorEntity
from app.domain.repositories.color_repository import ColorRepository


class CreateColorUseCase:
    def __init__(self, repo: ColorRepository):
        self.repo = repo

    def execute(self, name: str, hexcode: str) -> ColorEntity:
        return self.repo.create(name=name, hexcode=hexcode)
