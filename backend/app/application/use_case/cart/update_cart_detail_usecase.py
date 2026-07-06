from fastapi import HTTPException, status

from app.domain.repositories.cart_repository import CartRepository
from app.domain.repositories.warehouse_repository import WarehouseRepository


class UpdateCartDetailUseCase:
    def __init__(self, cart_repo: CartRepository, warehouse_repo: WarehouseRepository):
        self.cart_repo = cart_repo
        self.warehouse_repo = warehouse_repo

    def execute(self, user_id: int, detail_id: int, new_quantity: int) -> dict:
        cart = self.cart_repo.get_by_user_id(user_id)
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")

        detail = self.cart_repo.get_detail_by_id(detail_id)
        if not detail or detail.cart_id != cart.id:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng trong giỏ")

        pd = self.cart_repo.get_product_detail_by_id(detail.product_detail_id)
        if pd and not pd["is_active"]:
            raise HTTPException(status_code=400, detail="Sản phẩm trong giỏ đã ngừng bán, vui lòng xóa khỏi giỏ hàng")
        if pd:
            stock = self.warehouse_repo.get_total_stock(
                product_id=pd["product_id"],
                size_id=pd["size_id"],
                color_id=pd["color_id"],
            )
            if stock < new_quantity:
                raise HTTPException(status_code=400, detail=f"Kho chỉ còn {stock} sản phẩm")

        self.cart_repo.update_detail_quantity(detail_id, new_quantity)

        return self.cart_repo.get_cart_response(user_id)
