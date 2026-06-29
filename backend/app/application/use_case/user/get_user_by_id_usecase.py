from fastapi import HTTPException, status
from app.domain.repositories.user_repository import UserRepository
from app.domain.repositories.profile_repository import ProfileRepository


class GetUserByIdUseCase:
    def __init__(self, user_repo: UserRepository, profile_repo: ProfileRepository):
        self.user_repo = user_repo
        self.profile_repo = profile_repo

    def execute(self, user_id: int) -> dict:
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy tài khoản",
            )

        profile = self.profile_repo.get_by_user_id(user_id)

        result = {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "role": user.role,
            "created_at": user.created_at,
        }

        if profile:
            result["profile"] = {
                "name": profile.name,
                "phone": profile.phone,
                "gender": profile.gender,
                "birthday": profile.birthday,
                "avatar": profile.avatar,
            }
        else:
            result["profile"] = None

        return result
