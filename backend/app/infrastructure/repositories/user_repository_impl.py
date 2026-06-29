import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.user_mapper import UserMapper
from app.domain.entities.user_entity import UserEntity
from app.domain.repositories.user_repository import UserRepository
from app.infrastructure.database.models.user import User, UserRole


class UserRepositoryImpl(UserRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_first_by_role(self, role: str) -> Optional[UserEntity]:
        user = self.db.query(User).filter(User.role == UserRole(role)).order_by(User.id.asc()).first()
        if not user:
            return None
        return UserMapper.to_entity(user)

    def get_by_id(self, id: int) -> Optional[UserEntity]:
        model = self.db.query(User).filter(User.id == id).first()
        if not model:
            return None
        return UserMapper.to_entity(model)

    def get_by_email(self, email: str) -> Optional[UserEntity]:
        model = self.db.query(User).filter(User.email == email).first()
        if not model:
            return None
        return UserMapper.to_entity(model)

    def get_by_username(self, username: str) -> Optional[UserEntity]:
        model = self.db.query(User).filter(User.username == username).first()
        if not model:
            return None
        return UserMapper.to_entity(model)

    def get_all(self, page: int = 1, per_page: Optional[int] = None,
                keyword: Optional[str] = None, role: Optional[str] = None) -> dict:
        query = (
            self.db.query(User)
            .options(joinedload(User.profile))
            .filter(User.role == UserRole.USER)
        )

        if keyword:
            like = f"%{keyword}%"
            query = query.filter(or_(User.email.ilike(like), User.username.ilike(like)))

        if role:
            try:
                role_enum = UserRole(role)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Role không hợp lệ",
                )
            if role_enum != UserRole.USER:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Chỉ hỗ trợ quản lý tài khoản người dùng",
                )

        total_count = query.count()
        if total_count == 0:
            return {
                "items": [],
                "meta": {
                    "total": 0,
                    "current_page": 1,
                    "per_page": per_page or 0,
                    "last_page": 1,
                },
            }

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        models = query.order_by(User.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)

        return {
            "items": [UserMapper.to_entity(m) for m in models],
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }

    def create(self, email: str, username: str, password: str, role: str = "user") -> UserEntity:
        model = User(
            email=email,
            username=username,
            password=password,
            role=UserRole(role) if role in ("admin", "user") else UserRole.USER,
        )
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return UserMapper.to_entity(model)

    def update(self, id: int, data: dict) -> UserEntity:
        model = self.db.query(User).filter(User.id == id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy tài khoản",
            )
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return UserMapper.to_entity(model)

    def exists_by_email(self, email: str, exclude_id: Optional[int] = None) -> bool:
        query = self.db.query(User).filter(User.email == email)
        if exclude_id is not None:
            query = query.filter(User.id != exclude_id)
        return query.first() is not None

    def count_all(self) -> int:
        return self.db.query(func.count(User.id)).scalar() or 0

    def exists_by_username(self, username: str, exclude_id: Optional[int] = None) -> bool:
        query = self.db.query(User).filter(User.username == username)
        if exclude_id is not None:
            query = query.filter(User.id != exclude_id)
        return query.first() is not None
