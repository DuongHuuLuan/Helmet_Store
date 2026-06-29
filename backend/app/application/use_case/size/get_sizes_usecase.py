from app.domain.entities.size_entity import SizeEntity
from app.domain.repositories.size_repository import SizeRepository


class GetSizesUseCase:
    def __init__(self, repo: SizeRepository):
        self.repo = repo

    def execute(self) -> list[SizeEntity]:
        return self.repo.get_all()
