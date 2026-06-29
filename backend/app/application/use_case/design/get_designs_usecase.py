from app.domain.repositories.design_repository import DesignRepository


class GetDesignsUseCase:
    def __init__(self, design_repo: DesignRepository):
        self.design_repo = design_repo

    def execute(self, user_id: int) -> list[dict]:
        return self.design_repo.get_by_user_id_with_details(user_id)
