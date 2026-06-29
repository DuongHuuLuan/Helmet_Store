from app.domain.repositories.distributor_repository import DistributorRepository
from app.application.dto.distributor_dto import DistributorCreate


class CreateDistributorUseCase:
    def __init__(self, repo: DistributorRepository):
        self.repo = repo

    def execute(self, distributor_in: DistributorCreate) -> dict:
        entity = self.repo.create(distributor_in.model_dump())
        return {
            "id": entity.id,
            "name": entity.name,
            "email": entity.email,
            "address": entity.address,
            "can_delete": True,
        }
