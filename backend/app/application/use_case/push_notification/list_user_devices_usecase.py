from app.domain.repositories.user_device_repository import UserDeviceRepository


class ListUserDevicesUseCase:
    def __init__(self, device_repo: UserDeviceRepository):
        self.device_repo = device_repo

    def execute(self, user_id: int) -> list:
        return self.device_repo.list_by_user(user_id)
