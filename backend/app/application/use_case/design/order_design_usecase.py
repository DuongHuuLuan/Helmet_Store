from fastapi import HTTPException, status

from app.domain.repositories.design_repository import DesignRepository
from app.domain.repositories.cart_repository import CartRepository
from app.domain.repositories.warehouse_repository import WarehouseRepository
from app.application.use_case.cart.add_to_cart_usecase import AddToCartUseCase
from app.application.dto.design_dto import DesignOrderIn
from app.application.dto.cart_dto import CartDetailCreate


class OrderDesignUseCase:
    def __init__(
        self,
        design_repo: DesignRepository,
        cart_repo: CartRepository,
        warehouse_repo: WarehouseRepository,
    ):
        self.design_repo = design_repo
        self.cart_repo = cart_repo
        self.warehouse_repo = warehouse_repo

    def execute(self, user_id: int, design_id: int, order_in: DesignOrderIn) -> dict:
        entity = self.design_repo.get_by_id(design_id)
        if not entity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy thiết kế",
            )
        if entity.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền truy cập thiết kế này",
            )

        product_detail_id = order_in.product_detail_id
        if product_detail_id is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không tìm thấy biến thể sản phẩm",
            )

        uc = AddToCartUseCase(self.cart_repo, self.warehouse_repo)
        cart = uc.execute(
            user_id=user_id,
            data=CartDetailCreate(
                product_detail_id=product_detail_id,
                design_id=entity.id,
                quantity=order_in.quantity,
            ),
        )

        cart_detail = next(
            (
                item
                for item in cart["cart_details"]
                if item["product_detail_id"] == product_detail_id
                and item["design_id"] == entity.id
            ),
            None,
        )
        if cart_detail is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể đưa thiết kế vào giỏ hàng",
            )

        return {
            "message": "Đã đưa thiết kế vào giỏ hàng",
            "cart_id": cart["id"],
            "cart_detail_id": cart_detail["id"],
            "design_id": entity.id,
        }
