from fastapi import HTTPException

from app.domain.repositories.user_device_repository import UserDeviceRepository


class DeactivateUserDeviceUseCase:
    def __init__(self, device_repo: UserDeviceRepository):
        self.device_repo = device_repo

    def execute(self, user_id: int, push_token: str) -> bool:
        token = (push_token or "").strip()
        if not token:
            raise HTTPException(status_code=400, detail="push_token không hợp lệ")
        return self.device_repo.deactivate_by_user_and_token(user_id, token)
