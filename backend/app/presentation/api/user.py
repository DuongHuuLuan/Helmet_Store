from fastapi import APIRouter, Depends
from typing import Optional

from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.user_dto import UserAdminOut, UserPaginationOut

from app.shared.dependencies import (
    get_users_use_case, get_user_by_id_use_case,
    GetUsersUseCase, GetUserByIdUseCase,
)

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/", response_model=UserPaginationOut)
def get_all_users(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    role: Optional[str] = "user",
    current_admin: User = Depends(require_admin),
    use_case: GetUsersUseCase = Depends(get_users_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q, role=role)


@router.get("/{user_id}", response_model=UserAdminOut)
def get_user_id(
    user_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetUserByIdUseCase = Depends(get_user_by_id_use_case),
):
    return use_case.execute(user_id)
