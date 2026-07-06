from fastapi import APIRouter, Depends, File, UploadFile
from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.profile_dto import ProfileOut, ProfileUpdate

from app.shared.dependencies import (
    get_my_profile_use_case, get_update_my_profile_use_case,
    get_upload_avatar_use_case,
    GetMyProfileUseCase, UpdateMyProfileUseCase, UploadMyAvatarUseCase,
)

router = APIRouter(prefix="/profile", tags=["Profile"])


@router.get("/me", response_model=ProfileOut)
def get_profile(
    current_user: User = Depends(require_user),
    use_case: GetMyProfileUseCase = Depends(get_my_profile_use_case),
):
    return use_case.execute(user_id=current_user.id, username=current_user.username)


@router.put("/me", response_model=ProfileOut)
def update_profile(
    profile_in: ProfileUpdate,
    current_user: User = Depends(require_user),
    use_case: UpdateMyProfileUseCase = Depends(get_update_my_profile_use_case),
):
    return use_case.execute(
        user_id=current_user.id,
        username=current_user.username,
        profile_in=profile_in,
    )


@router.post("/me/avatar", response_model=ProfileOut)
def upload_my_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(require_user),
    use_case: UploadMyAvatarUseCase = Depends(get_upload_avatar_use_case),
):
    return use_case.execute(
        user_id=current_user.id,
        username=current_user.username,
        file=file,
    )
