from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Any, Union
from jose import jwt 

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated = "auto")

def get_password_hash(password: str) -> str:
    """Băm mật khẩu thành chuổi ký tự bảo mật"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """So sánh mật khẩu thuần với bản băm trong DB"""
    return pwd_context.verify(plain_password, hashed_password)

def created_access_token(subject: Union[str, Any],role: str = None, expires_delta: timedelta = None) -> str:
    """Tạo JWT Token chứa cả ID người dùng và Role"""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode = {"exp": expire, "sub": str(subject), "type": "access"}
    if role:
        to_encode.update({"role": role})

    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def create_refresh_token(subject: Union[str, Any]) -> str:
    """Tạo Refresh Token có thời hạn dài hơn"""
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt