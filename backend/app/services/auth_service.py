from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User
from app.models.profile import Profile
from jose import jwt, JWTError
from app.core.security import get_password_hash, verify_password, created_access_token, create_refresh_token
from app.core.config import settings
from app.schemas.user import UserCreate, PasswordChange

class AuthService:
    @staticmethod
    def register_user(db: Session, user_in: UserCreate,  role: str = "user"):
        if db.query(User).filter(User.email == user_in.email).first():
            raise HTTPException(status_code=400, detail="Email đã tồn tại")
        
        # tạo user với mật khẩu đã băm
        db_user = User(
            email = user_in.email,
            username = user_in.username,
            password = get_password_hash(user_in.password),
            role = role
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # tạo profile đi kèm
        db_profile = Profile(
            user_id = db_user.id,
            name = db_user.username,
            gender = "male"
        )
        db.add(db_profile)
        db.commit()
        return db_user
    
    @staticmethod
    def login_user(db: Session, email: str, password: str):
        user = db.query(User).filter(User.email == email).first()
        if not user or not verify_password(password, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sai email hoặc mật khẩu"
            )
        
        # tạo token chứa sub(ID) và role
        token = created_access_token(
            subject=user.id,
            role=user.role.value 
        )
        refresh_token = create_refresh_token(subject=user.id)
        return {
            "access_token": token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": user
        }
    
    @staticmethod
    def refresh_access_token(db: Session, refresh_token: str):
        try:
            payload = jwt.decode(
                refresh_token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM]
            )
            if payload.get("type") != "refresh":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token không hợp lệ"
                )
            user_id = payload.get("sub")
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User không tồn tại"
                )
            new_access = created_access_token(subject=user.id, role=user.role.value)
            new_refresh = create_refresh_token(subject=user.id)
            return {
                "access_token": new_access,
                "refresh_token": new_refresh,
                "token_type": "bearer",
            }
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token hết hạn hoặc không hợp lệ"
            )

    @staticmethod
    def change_password(db: Session, current_user: User, password: PasswordChange ):
        if not verify_password(password.old_password, current_user.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mật khẩu cũ không chính xác"
            )
        
        current_user.password = get_password_hash(password.new_password)

        db.add(current_user)
        db.commit()
        db.refresh(current_user)
        return {"Message:": "Đổi mật khẩu thành công"}

auth_service = AuthService()
