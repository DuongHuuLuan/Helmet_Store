from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database.mappers.profile_mapper import ProfileMapper
from app.domain.entities.profile_entity import ProfileEntity
from app.domain.repositories.profile_repository import ProfileRepository
from app.infrastructure.database.models.profile import Profile
from app.infrastructure.database.models.user import User


class ProfileRepositoryImpl(ProfileRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_user_id(self, user_id: int) -> Optional[ProfileEntity]:
        model = self.db.query(Profile).filter(Profile.user_id == user_id).first()
        if not model:
            return None
        return ProfileMapper.to_entity(model)

    def get_or_create(self, user_id: int, name: str) -> ProfileEntity:
        model = self.db.query(Profile).filter(Profile.user_id == user_id).first()
        if model:
            return ProfileMapper.to_entity(model)

        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy người dùng",
            )

        model = Profile(user_id=user.id, name=name)
        self.db.add(model)
        self.db.flush()
        return ProfileMapper.to_entity(model)

    def update(self, user_id: int, data: dict) -> ProfileEntity:
        model = self.db.query(Profile).filter(Profile.user_id == user_id).first()
        if not model:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy profile",
            )
        for key, value in data.items():
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ProfileMapper.to_entity(model)
