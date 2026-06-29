from app.domain.entities.user_entity import UserEntity
from app.infrastructure.database.models.user import User


class UserMapper:
    @staticmethod
    def to_entity(model: User) -> UserEntity:
        return UserEntity(
            id=model.id,
            email=model.email,
            username=model.username,
            password=model.password,
            role=model.role.value if hasattr(model.role, 'value') else model.role,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: UserEntity) -> User:
        return User(
            id=entity.id,
            email=entity.email,
            username=entity.username,
            password=entity.password,
            role=entity.role,
        )
