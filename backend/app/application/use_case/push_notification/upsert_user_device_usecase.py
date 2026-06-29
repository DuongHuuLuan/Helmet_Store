from datetime import datetime
from typing import Optional

from fastapi import HTTPException

from app.domain.entities.user_device_entity import UserDeviceEntity
from app.domain.repositories.user_device_repository import UserDeviceRepository


class UpsertUserDeviceUseCase:
    def __init__(self, device_repo: UserDeviceRepository):
        self.device_repo = device_repo

    def execute(self, user_id: int, platform: str, push_token: str,
                device_id: Optional[str] = None) -> UserDeviceEntity:
        token = (push_token or "").strip()
        if not token:
            raise HTTPException(status_code=400, detail="push_token không được rỗng")

        existing = self.device_repo.get_by_push_token(token)
        if existing:
            existing.user_id = user_id
            existing.platform = platform
            existing.device_id = device_id
            existing.is_active = True
            existing.last_seen_at = datetime.utcnow()
            return self.device_repo.update(existing)

        if device_id:
            same_device = self.device_repo.get_by_user_and_device_id(user_id, device_id)
            if same_device:
                same_device.platform = platform
                same_device.push_token = token
                same_device.is_active = True
                same_device.last_seen_at = datetime.utcnow()
                return self.device_repo.update(same_device)

        return self.device_repo.create(
            user_id=user_id,
            platform=platform,
            push_token=token,
            device_id=device_id,
        )
