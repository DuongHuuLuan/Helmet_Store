import cloudinary.uploader
from app.domain.repositories.image_url_repository import ImageUrlRepository


class DeleteAllImagesUseCase:
    def __init__(self, image_repo: ImageUrlRepository):
        self.image_repo = image_repo

    def execute(self, product_id: int) -> dict:
        images = self.image_repo.get_by_product_id(product_id)
        for img in images:
            if img.public_id:
                try:
                    cloudinary.uploader.destroy(img.public_id)
                except Exception:
                    pass
        self.image_repo.delete_all_by_product(product_id)
        return {"message": "Đã xóa toàn bộ ảnh của sản phẩm"}
