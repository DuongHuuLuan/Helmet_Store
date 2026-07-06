from fastapi import HTTPException, status
from jose import jwt, JWTError
from app.core.config import settings
from app.core.security import created_access_token, create_refresh_token
from app.domain.repositories.user_repository import UserRepository


class RefreshTokenUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def execute(self, refresh_token: str) -> dict:
        try:
            payload = jwt.decode(
                refresh_token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM],
            )
            if payload.get("type") != "refresh":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token không hợp lệ",
                )
            user_id = int(payload.get("sub"))
            user = self.user_repo.get_by_id(user_id)
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User không tồn tại",
                )
            new_access = created_access_token(subject=user.id, role=user.role)
            new_refresh = create_refresh_token(subject=user.id)
            return {
                "access_token": new_access,
                "refresh_token": new_refresh,
                "token_type": "bearer",
            }
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token hết hạn hoặc không hợp lệ",
            )
