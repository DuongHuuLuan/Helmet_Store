from app.domain.entities.size_entity import SizeEntity
from app.domain.repositories.size_repository import SizeRepository


class GetSizeByIdUseCase:
    def __init__(self, repo: SizeRepository):
        self.repo = repo

    def execute(self, id: int) -> SizeEntity:
        return self.repo.get_by_id(id)
