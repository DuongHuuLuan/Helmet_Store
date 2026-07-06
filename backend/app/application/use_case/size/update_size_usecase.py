from app.domain.entities.size_entity import SizeEntity
from app.domain.repositories.size_repository import SizeRepository


class UpdateSizeUseCase:
    def __init__(self, repo: SizeRepository):
        self.repo = repo

    def execute(self, id: int, size: str) -> SizeEntity:
        return self.repo.update(id=id, size=size)
