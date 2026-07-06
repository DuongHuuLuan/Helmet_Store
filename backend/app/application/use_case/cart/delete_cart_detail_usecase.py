from fastapi import HTTPException, status
from app.domain.repositories.cart_repository import CartRepository


class DeleteCartDetailUseCase:
    def __init__(self, cart_repo: CartRepository):
        self.cart_repo = cart_repo

    def execute(self, user_id: int, detail_id: int) -> dict:
        cart = self.cart_repo.get_by_user_id(user_id)
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")

        detail = self.cart_repo.get_detail_by_id(detail_id)
        if not detail or detail.cart_id != cart.id:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng trong giỏ hàng")

        self.cart_repo.delete_detail(detail_id)
        return {"message": "Đã xóa sản phẩm khỏi giỏ hàng"}
