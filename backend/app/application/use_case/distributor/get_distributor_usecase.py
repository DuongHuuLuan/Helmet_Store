from fastapi import HTTPException, status

from app.domain.repositories.distributor_repository import DistributorRepository


class GetDistributorUseCase:
    def __init__(self, repo: DistributorRepository):
        self.repo = repo

    def execute(self, distributor_id: int) -> dict:
        result = self.repo.get_by_id(distributor_id)
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Nhà cung cấp không tồn tại",
            )
        blocked = self.repo.get_blocked_ids([distributor_id])
        return {
            "id": result.id,
            "name": result.name,
            "email": result.email,
            "address": result.address,
            "can_delete": result.id not in blocked,
        }
