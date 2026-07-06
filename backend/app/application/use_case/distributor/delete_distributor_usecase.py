from app.domain.repositories.distributor_repository import DistributorRepository


class DeleteDistributorUseCase:
    def __init__(self, repo: DistributorRepository):
        self.repo = repo

    def execute(self, distributor_id: int) -> dict:
        self.repo.delete(distributor_id)
        return {"message": "Xóa thành công nhà cung cấp"}
