from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Dict, Optional

from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.discount_dto import (
    DiscountCreate,
    DiscountUpdate,
    DiscountOut,
    DiscountPaginationOut,
)
from app.application.use_case.discount.get_discounts_usecase import GetDiscountsUseCase
from app.application.use_case.discount.get_discount_by_id_usecase import GetDiscountByIdUseCase
from app.application.use_case.discount.create_discount_usecase import CreateDiscountUseCase
from app.application.use_case.discount.update_discount_usecase import UpdateDiscountUseCase
from app.application.use_case.discount.delete_discount_usecase import DeleteDiscountUseCase
from app.application.use_case.discount.get_valid_discount_usecase import GetValidDiscountUseCase
from app.application.use_case.discount.get_discounts_by_category_ids_usecase import GetDiscountsByCategoryIdsUseCase
from app.application.use_case.discount.get_available_discounts_for_cart_usecase import GetAvailableDiscountsForCartUseCase
from app.shared.dependencies import (
    get_discounts_use_case,
    get_create_discount_use_case,
    get_update_discount_use_case,
    get_delete_discount_use_case,
    get_available_discounts_for_cart_use_case,
    get_valid_discount_use_case,
    get_discounts_by_category_ids_use_case,
    get_discount_by_id_use_case,
)

router = APIRouter(prefix="/discounts", tags=["Discount"])


@router.get("/discount-cart", response_model=List[DiscountOut])
def get_discount_by_cart(
    category_ids: List[int] = Query(...),
    use_case: GetAvailableDiscountsForCartUseCase = Depends(get_available_discounts_for_cart_use_case),
):
    return use_case.execute(category_ids)


@router.get("/check/{code_name}", response_model=DiscountOut)
def check_discount_code(
    code_name: str,
    use_case: GetValidDiscountUseCase = Depends(get_valid_discount_use_case),
):
    return use_case.execute(code_name)


@router.get("/by-categories", response_model=Dict[int, DiscountOut])
def get_discounts_by_categories(
    category_ids: List[int] = Query(...),
    use_case: GetDiscountsByCategoryIdsUseCase = Depends(get_discounts_by_category_ids_use_case),
):
    return use_case.execute(category_ids)


# --- Admin ---

@router.get("/", response_model=DiscountPaginationOut)
def get_all_discounts(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    current_admin: User = Depends(require_admin),
    use_case: GetDiscountsUseCase = Depends(get_discounts_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/{discount_id}", response_model=DiscountOut)
def get_discount_id(
    discount_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetDiscountByIdUseCase = Depends(get_discount_by_id_use_case),
):
    return use_case.execute(discount_id)


@router.post("/", response_model=DiscountOut, status_code=status.HTTP_201_CREATED)
def create_discount(
    discount_in: DiscountCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreateDiscountUseCase = Depends(get_create_discount_use_case),
):
    return use_case.execute(discount_in.model_dump())


@router.put("/{discount_id}", response_model=DiscountOut)
def update_discount(
    discount_id: int,
    discount_in: DiscountUpdate,
    current_admin: User = Depends(require_admin),
    use_case: UpdateDiscountUseCase = Depends(get_update_discount_use_case),
):
    return use_case.execute(discount_id, discount_in.model_dump(exclude_unset=True))


@router.delete("/{discount_id}", status_code=status.HTTP_200_OK)
def delete_discount(
    discount_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeleteDiscountUseCase = Depends(get_delete_discount_use_case),
):
    return use_case.execute(discount_id)
