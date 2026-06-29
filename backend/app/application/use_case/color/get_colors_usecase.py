from app.domain.entities.color_entity import ColorEntity
from app.domain.repositories.color_repository import ColorRepository

class GetColorsUseCase:
    def __init__(self, repo: ColorRepository):
        self.repo = repo
    def execute(self) -> list[ColorEntity]:
        return self.repo.get_all()