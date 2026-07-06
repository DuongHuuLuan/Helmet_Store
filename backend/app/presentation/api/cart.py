from fastapi import APIRouter, Depends, HTTPException

from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.cart_dto import CartOut, CartDetailCreate
from app.shared.dependencies import (
    get_add_to_cart_use_case,
    get_update_cart_detail_use_case,
    get_delete_cart_detail_use_case,
    get_cart_use_case,
)


router = APIRouter(prefix="/carts", tags=["Cart"])


@router.get("/", response_model=CartOut)
def get_cart(
    current_user: User = Depends(require_user),
    use_case=Depends(get_cart_use_case),
):
    return use_case.execute(current_user.id)


@router.post("/cart-details", response_model=CartOut)
def add_to_cart(
    cart_detail_in: CartDetailCreate,
    current_user: User = Depends(require_user),
    use_case=Depends(get_add_to_cart_use_case),
):
    return use_case.execute(current_user.id, cart_detail_in)


@router.put("/cart-details/{cart_detail_id}", response_model=CartOut)
def update_cart(
    cart_detail_id: int,
    new_quantity: int,
    current_user: User = Depends(require_user),
    use_case=Depends(get_update_cart_detail_use_case),
):
    if new_quantity <= 0:
        raise HTTPException(status_code=400, detail="Số lượng phải lớn hơn 0")
    return use_case.execute(current_user.id, cart_detail_id, new_quantity)


@router.delete("/cart-details/{cart_detail_id}")
def delete_cart(
    cart_detail_id: int,
    current_user: User = Depends(require_user),
    use_case=Depends(get_delete_cart_detail_use_case),
):
    return use_case.execute(current_user.id, cart_detail_id)
