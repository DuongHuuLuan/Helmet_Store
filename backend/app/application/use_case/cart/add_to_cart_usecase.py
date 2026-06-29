from fastapi import HTTPException, status
from app.domain.repositories.cart_repository import CartRepository
from app.domain.repositories.warehouse_repository import WarehouseRepository
from app.application.dto.cart_dto import CartDetailCreate


class AddToCartUseCase:
    def __init__(self, cart_repo: CartRepository, warehouse_repo: WarehouseRepository):
        self.cart_repo = cart_repo
        self.warehouse_repo = warehouse_repo

    def execute(self, user_id: int, data: CartDetailCreate) -> dict:
        cart = self.cart_repo.get_or_create(user_id)

        product_detail = self.cart_repo.get_product_detail_by_id(data.product_detail_id)
        if not product_detail:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        if not product_detail["is_active"]:
            raise HTTPException(status_code=400, detail="Biến thể sản phẩm đã ngừng bán")

        design_id = None
        if data.design_id and data.design_id > 0:
            design = self.cart_repo.get_design_by_id(data.design_id)
            if not design:
                raise HTTPException(status_code=404, detail="Thiết kế không tồn tại")
            if design["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="Bạn không có quyền dùng thiết kế này")
            if design["product_id"] != product_detail["product_id"]:
                raise HTTPException(status_code=400, detail="Thiết kế không thuộc biến thể sản phẩm đã chọn")
            design_id = design["id"]

        stock = self.warehouse_repo.get_total_stock(
            product_id=product_detail["product_id"],
            size_id=product_detail["size_id"],
            color_id=product_detail["color_id"],
        )
        if stock < data.quantity:
            raise HTTPException(status_code=400, detail=f"Chỉ còn {stock} sản phẩm trong kho")

        existing = self.cart_repo.find_existing_detail(cart.id, data.product_detail_id, design_id)
        if existing:
            new_qty = existing.quantity + data.quantity
            if stock < new_qty:
                raise HTTPException(status_code=400, detail="Tổng số lượng vượt quá tồn kho")
            self.cart_repo.update_detail_quantity(existing.id, new_qty)
        else:
            self.cart_repo.add_detail(cart.id, data.product_detail_id, design_id, data.quantity)

        return self.cart_repo.get_cart_response(user_id)
