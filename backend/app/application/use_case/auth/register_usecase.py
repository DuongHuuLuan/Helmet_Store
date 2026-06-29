from fastapi import HTTPException
from app.core.security import get_password_hash
from app.domain.repositories.user_repository import UserRepository
from app.domain.repositories.profile_repository import ProfileRepository
from app.domain.entities.user_entity import UserEntity
from app.application.dto.user_dto import UserCreate


class RegisterUseCase:
    def __init__(self, user_repo: UserRepository, profile_repo: ProfileRepository):
        self.user_repo = user_repo
        self.profile_repo = profile_repo

    def execute(self, user_in: UserCreate, role: str = "user") -> UserEntity:
        exists = self.user_repo.get_by_email(user_in.email)
        if exists:
            raise HTTPException(status_code=400, detail="Email đã tồn tại")

        hashed = get_password_hash(user_in.password)
        user = self.user_repo.create(
            email=user_in.email,
            username=user_in.username,
            password=hashed,
            role=role,
        )

        self.profile_repo.get_or_create(user_id=user.id, name=user.username)

        return user
