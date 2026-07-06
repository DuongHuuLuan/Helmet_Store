from app.domain.entities.color_entity import ColorEntity
from app.domain.repositories.color_repository import ColorRepository


class GetColorByIdUseCase:
    def __init__(self, repo: ColorRepository):
        self.repo = repo

    def execute(self, id: int) -> ColorEntity:
        return self.repo.get_by_id(id)
