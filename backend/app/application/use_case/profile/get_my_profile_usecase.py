from app.domain.repositories.profile_repository import ProfileRepository
from app.domain.entities.profile_entity import ProfileEntity


class GetMyProfileUseCase:
    def __init__(self, profile_repo: ProfileRepository):
        self.profile_repo = profile_repo

    def execute(self, user_id: int, username: str) -> ProfileEntity:
        profile = self.profile_repo.get_or_create(user_id, name=username)
        return profile
