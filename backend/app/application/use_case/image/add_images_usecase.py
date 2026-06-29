from app.domain.repositories.image_url_repository import ImageUrlRepository
from app.domain.entities.image_url_entity import ImageUrlEntity


class AddImagesUseCase:
    def __init__(self, image_repo: ImageUrlRepository):
        self.image_repo = image_repo

    def execute(self, product_id: int, images: list[dict]) -> list[ImageUrlEntity]:
        return self.image_repo.create_many(product_id, images)
