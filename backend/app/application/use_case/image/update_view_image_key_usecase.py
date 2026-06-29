from app.domain.repositories.image_url_repository import ImageUrlRepository
from app.domain.entities.image_url_entity import ImageUrlEntity


class UpdateViewImageKeyUseCase:
    def __init__(self, image_repo: ImageUrlRepository):
        self.image_repo = image_repo

    def execute(self, image_id: int, view_image_key: str, product_id: int = None) -> ImageUrlEntity:
        entity = self.image_repo.get_by_id(image_id)
        if not entity:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found")
        if product_id is not None and entity.product_id != product_id:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found")
        return self.image_repo.update(image_id, {"view_image_key": view_image_key})
