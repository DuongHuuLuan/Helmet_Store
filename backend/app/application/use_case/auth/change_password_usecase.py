from fastapi import HTTPException, status
from app.core.security import verify_password, get_password_hash
from app.domain.repositories.user_repository import UserRepository
from app.application.dto.user_dto import PasswordChange


class ChangePasswordUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    def execute(self, user_id: int, passwords: PasswordChange) -> dict:
        user = self.user_repo.get_by_id(user_id)

        if not verify_password(passwords.old_password, user.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mật khẩu cũ không chính xác",
            )

        new_hashed = get_password_hash(passwords.new_password)
        self.user_repo.update(user_id, {"password": new_hashed})

        return {"Message": "Đổi mật khẩu thành công"}
