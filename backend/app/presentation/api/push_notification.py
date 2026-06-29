from typing import List

from fastapi import APIRouter, Depends, Query

from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.push_notification_dto import UserDeviceOut, UserDeviceUpsertIn

from app.shared.dependencies import (
    get_list_devices_use_case, get_upsert_device_use_case,
    get_deactivate_device_use_case,
    ListUserDevicesUseCase, UpsertUserDeviceUseCase, DeactivateUserDeviceUseCase,
)

router = APIRouter(prefix="/push", tags=["Push Notification"])


@router.get("/devices", response_model=List[UserDeviceOut])
def list_my_devices(
    current_user: User = Depends(require_user),
    use_case: ListUserDevicesUseCase = Depends(get_list_devices_use_case),
):
    return use_case.execute(user_id=current_user.id)


@router.post("/devices", response_model=UserDeviceOut)
def register_device(
    payload: UserDeviceUpsertIn,
    current_user: User = Depends(require_user),
    use_case: UpsertUserDeviceUseCase = Depends(get_upsert_device_use_case),
):
    return use_case.execute(
        user_id=current_user.id,
        platform=payload.platform,
        push_token=payload.push_token,
        device_id=payload.device_id,
    )


@router.delete("/devices")
def deactivate_device(
    push_token: str = Query(..., min_length=20, max_length=512),
    current_user: User = Depends(require_user),
    use_case: DeactivateUserDeviceUseCase = Depends(get_deactivate_device_use_case),
):
    deleted = use_case.execute(user_id=current_user.id, push_token=push_token)
    return {"success": True, "deactivated": deleted}
