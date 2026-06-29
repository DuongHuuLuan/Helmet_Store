import cloudinary.uploader
from fastapi import UploadFile
from app.domain.repositories.image_url_repository import ImageUrlRepository
from app.domain.entities.image_url_entity import ImageUrlEntity


class ReplaceImageUseCase:
    def __init__(self, image_repo: ImageUrlRepository):
        self.image_repo = image_repo

    def execute(self, image_id: int, new_file: UploadFile, product_id: int = None) -> ImageUrlEntity:
        entity = self.image_repo.get_by_id(image_id)
        if not entity:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found")
        if product_id is not None and entity.product_id != product_id:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found")

        old_public_id = entity.public_id
        result = cloudinary.uploader.upload(new_file.file, folder="helmet_shop/products")

        entity = self.image_repo.update(image_id, {
            "url": result["secure_url"],
            "public_id": result["public_id"],
        })

        if old_public_id:
            try:
                cloudinary.uploader.destroy(old_public_id)
            except Exception:
                pass

        return entity
