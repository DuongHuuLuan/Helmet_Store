from app.domain.entities.profile_entity import ProfileEntity
from app.infrastructure.database.models.profile import Profile


class ProfileMapper:
    @staticmethod
    def to_entity(model: Profile) -> ProfileEntity:
        return ProfileEntity(
            id=model.id,
            user_id=model.user_id,
            name=model.name,
            phone=model.phone,
            gender=model.gender.value if model.gender and hasattr(model.gender, 'value') else model.gender,
            birthday=model.birthday,
            avatar=model.avatar,
            avatar_public_id=model.avatar_public_id,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: ProfileEntity) -> Profile:
        return Profile(
            id=entity.id,
            user_id=entity.user_id,
            name=entity.name,
            phone=entity.phone,
            gender=entity.gender,
            birthday=entity.birthday,
            avatar=entity.avatar,
            avatar_public_id=entity.avatar_public_id,
        )
