import cloudinary.uploader
from app.domain.repositories.image_url_repository import ImageUrlRepository


class DeleteImageUseCase:
    def __init__(self, image_repo: ImageUrlRepository):
        self.image_repo = image_repo

    def execute(self, image_id: int) -> dict:
        entity = self.image_repo.get_by_id(image_id)
        if entity:
            cloudinary.uploader.destroy(entity.public_id)
        self.image_repo.delete(image_id)
        return {"message": "Xóa ảnh thành công"}
