from fastapi import HTTPException, status
from app.domain.repositories.profile_repository import ProfileRepository
from app.domain.repositories.user_repository import UserRepository
from app.domain.entities.profile_entity import ProfileEntity
from app.application.dto.profile_dto import ProfileUpdate


class UpdateMyProfileUseCase:
    def __init__(self, profile_repo: ProfileRepository, user_repo: UserRepository):
        self.profile_repo = profile_repo
        self.user_repo = user_repo

    def execute(self, user_id: int, username: str, profile_in: ProfileUpdate) -> ProfileEntity:
        profile = self.profile_repo.get_or_create(user_id, name=username)

        update_data = profile_in.model_dump(exclude_unset=True)

        if "name" in update_data:
            new_name = (update_data.get("name") or "").strip()
            if not new_name:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Tên không được để trống",
                )

            exists = self.user_repo.exists_by_username(new_name, exclude_id=user_id)
            if exists:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username đã tồn tại",
                )

            update_data["name"] = new_name
            self.user_repo.update(user_id, {"username": new_name})

        profile = self.profile_repo.update(user_id, update_data)
        return profile
