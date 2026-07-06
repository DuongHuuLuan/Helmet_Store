from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.user import UserCreate, UserOut, PasswordChange
from app.services.auth_service import auth_service
from app.api import deps
from app.models.user import User
from pydantic import BaseModel, EmailStr
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(prefix="/auth", tags=["Authentication"])

#schema dùng cho request đăng nhập
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    Tạo tài khoản mới. Mặc định role là 'user'
    """
    return auth_service.register_user(db, user_in)

@router.post("/login/user")
def login_user(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    API Đăng nhập dành riêng cho USER trả về token, và thông tin user 
    """
    auth_result = auth_service.login_user(db,email=form_data.username,password=form_data.password)
    if auth_result["user"].role != "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tài khoản này không có quyền truy cập ứng dụng")
    return auth_result

@router.post("/login/admin")    
def login_admin(form_data: OAuth2PasswordRequestForm = Depends(),db: Session = Depends(get_db)):
    """ API đăng nhập dành riêng cho ADMIN"""
    print(f"Đang đăng nhập với  email: {form_data.username}")
    auth_result = auth_service.login_user(db, email=form_data.username,password=form_data.password)

    if auth_result["user"].role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bạn không có quyền truy cập trang quản trị")
    
    return auth_result

class RefreshRequest(BaseModel):
    refresh_token: str

@router.post("/refresh")
def refresh_token(body: RefreshRequest, db: Session = Depends(get_db)):
    """
    API cấp lại access_token mới dựa vào refresh_token
    """
    return auth_service.refresh_access_token(db, body.refresh_token)

@router.post("/change-password")
def change_password(
    password: PasswordChange,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user) ## bắt buộc đăng nhập mới được đổi mật khẩu
):
    """"
    API đổi mật khẩu cho người dùng đang đăng nhập
    """
    return auth_service.change_password(db, current_user, password)


@router.get("/me", response_model=UserOut)
def read_user_me(current_user: User = Depends(deps.get_current_user)):
    """
    Lấy thông tin người dùng đang đăng nhập dựa vào Token gửi kèm.
    """
    return current_user

# API thử nghiệm quyền Admin
@router.get("/admin")
def test_admin_access(admin_user: User = Depends(deps.require_admin)):
    """
    API Test để xem chức năng phân quyền Admin có hoạt động khoogn. 
    """
    return {"message":f"Chào Amin{admin_user.username}, bạn có quyền truy cập! "}