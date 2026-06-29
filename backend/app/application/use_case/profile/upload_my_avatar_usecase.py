import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from app.domain.repositories.profile_repository import ProfileRepository
from app.domain.entities.profile_entity import ProfileEntity


class UploadMyAvatarUseCase:
    def __init__(self, profile_repo: ProfileRepository):
        self.profile_repo = profile_repo

    def execute(self, user_id: int, username: str, file: UploadFile) -> ProfileEntity:
        if not (file.content_type or "").startswith("image/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File phải là ảnh",
            )

        profile = self.profile_repo.get_or_create(user_id, name=username)
        old_public_id = None
        new_public_id = None

        try:
            upload_result = cloudinary.uploader.upload(
                file.file,
                folder="helmet_shop/avatars",
            )
            avatar_url = upload_result.get("secure_url")
            new_public_id = upload_result.get("public_id")

            profile = self.profile_repo.update(user_id, {
                "avatar": avatar_url,
                "avatar_public_id": new_public_id,
            })
        except Exception:
            if new_public_id:
                try:
                    cloudinary.uploader.destroy(new_public_id)
                except Exception:
                    pass
            raise

        if old_public_id and old_public_id != new_public_id:
            try:
                cloudinary.uploader.destroy(old_public_id)
            except Exception:
                pass

        return profile
