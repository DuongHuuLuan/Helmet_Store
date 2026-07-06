from app.domain.repositories.distributor_repository import DistributorRepository
from app.application.dto.distributor_dto import DistributorCreate


class UpdateDistributorUseCase:
    def __init__(self, repo: DistributorRepository):
        self.repo = repo

    def execute(self, distributor_id: int,
                distributor_in: DistributorCreate) -> dict:
        entity = self.repo.update(distributor_id, distributor_in.model_dump())
        blocked = self.repo.get_blocked_ids([distributor_id])
        return {
            "id": entity.id,
            "name": entity.name,
            "email": entity.email,
            "address": entity.address,
            "can_delete": entity.id not in blocked,
        }
