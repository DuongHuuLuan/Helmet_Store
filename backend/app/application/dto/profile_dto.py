from pydantic import BaseModel, HttpUrl, Field
from typing import Optional
from datetime import datetime, date
from enum import Enum
from app.application.dto.user_dto import UserOut

class GenderEnum(str, Enum):
    male = "male"
    female = "female"
    other = "other"

class ProfileBase(BaseModel):
    name: Optional[str] = Field(None, max_length=50, description="Họ và tên")
    phone: Optional[str] = Field(None, pattern=r"^\+?1?\d{9,15}$", description="Số điện thoại") # Validation số điện thoại
    gender: Optional[GenderEnum] = Field(None, description="Giới tính: Nam, Nữ hoặc Khác")
    birthday:  Optional[date] = Field(None, description="Ngày sinh")
    avatar: Optional[str] = None

#schema dùng để tạo profile (dùng khi user cập nhật profile lần đầu)
class ProfileCreate(ProfileBase):
    user_id: int

#schema dùng để cập nhật profile
class ProfileUpdate(ProfileBase):
    pass


#schema dùng để trả về dữ liệu profile cho frontend
class ProfileOut(ProfileBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# khi lấy profile, trả về luôn cả thông tin user
class ProfileWithUserOut(ProfileOut):
    user: UserOut