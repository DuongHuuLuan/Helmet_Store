from pydantic import BaseModel, EmailStr, Field
from datetime import datetime, date
from typing import Optional, List
from app.infrastructure.database.models.user import UserRole

class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str

class PasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6)

class UserOut(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    role: Optional[UserRole] = None

class UserProfileSummaryOut(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    gender: Optional[str] = None
    birthday: Optional[date] = None
    avatar: Optional[str] = None

    class Config:
        from_attributes = True

class UserAdminOut(UserBase):
    id: int
    role: UserRole
    created_at: datetime
    profile: Optional[UserProfileSummaryOut] = None

    class Config:
        from_attributes = True

class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int

class UserPaginationOut(BaseModel):
    items: List[UserAdminOut]
    meta: PaginationMeta
