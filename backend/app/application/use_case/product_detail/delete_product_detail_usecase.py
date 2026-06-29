from app.domain.repositories.product_detail_repository import ProductDetailRepository


class DeleteProductDetailUseCase:
    def __init__(self, detail_repo: ProductDetailRepository):
        self.detail_repo = detail_repo

    def execute(self, detail_id: int) -> dict:
        self.detail_repo.delete(detail_id)
        return {"message": "Đã xóa biến thể sản phẩm thành công"}
