from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.infrastructure.database.session import get_db
from app.application.dto.user_dto import UserCreate, UserOut, PasswordChange
from app.presentation.api import deps
from app.domain.entities.user_entity import UserEntity as User
from pydantic import BaseModel, EmailStr
from fastapi.security import OAuth2PasswordRequestForm

from app.shared.dependencies import (
    get_register_use_case, get_login_use_case,
    get_refresh_token_use_case, get_change_password_use_case,
    RegisterUseCase, LoginUseCase, RefreshTokenUseCase, ChangePasswordUseCase,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(
    user_in: UserCreate,
    use_case: RegisterUseCase = Depends(get_register_use_case),
):
    return use_case.execute(user_in)


@router.post("/login/user")
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    use_case: LoginUseCase = Depends(get_login_use_case),
):
    auth_result = use_case.execute(email=form_data.username, password=form_data.password)
    if auth_result["user"].role != "user":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản này không có quyền truy cập ứng dụng",
        )
    return auth_result


@router.post("/login/admin")
def login_admin(
    form_data: OAuth2PasswordRequestForm = Depends(),
    use_case: LoginUseCase = Depends(get_login_use_case),
):
    auth_result = use_case.execute(email=form_data.username, password=form_data.password)
    if auth_result["user"].role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập trang quản trị",
        )
    return auth_result


@router.post("/refresh")
def refresh_token(
    body: RefreshRequest,
    use_case: RefreshTokenUseCase = Depends(get_refresh_token_use_case),
):
    return use_case.execute(body.refresh_token)


@router.post("/change-password")
def change_password(
    password: PasswordChange,
    current_user: User = Depends(deps.get_current_user),
    use_case: ChangePasswordUseCase = Depends(get_change_password_use_case),
):
    return use_case.execute(user_id=current_user.id, passwords=password)


@router.get("/me", response_model=UserOut)
def read_user_me(
    current_user: User = Depends(deps.get_current_user),
):
    return current_user


@router.get("/admin")
def test_admin_access(admin_user: User = Depends(deps.require_admin)):
    return {"message": f"Chào admin {admin_user.username}, bạn có quyền truy cập!"}
