from app.domain.entities.size_entity import SizeEntity
from app.domain.repositories.size_repository import SizeRepository


class CreateSizeUseCase:
    def __init__(self, repo: SizeRepository):
        self.repo = repo

    def execute(self, size: str) -> SizeEntity:
        return self.repo.create(size=size)
