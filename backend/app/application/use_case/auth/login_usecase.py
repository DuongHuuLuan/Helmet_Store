from fastapi import HTTPException, status
from app.core.security import verify_password, created_access_token, create_refresh_token
from app.domain.repositories.user_repository import UserRepository
from app.domain.entities.user_entity import UserEntity


class LoginUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def execute(self, email: str, password: str) -> dict:
        user = self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sai email hoặc mật khẩu",
            )

        access_token = created_access_token(subject=user.id, role=user.role)
        refresh_token = create_refresh_token(subject=user.id)

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": user,
        }
