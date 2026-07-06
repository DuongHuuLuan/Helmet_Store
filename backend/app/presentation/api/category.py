from fastapi import APIRouter, Depends, status
from typing import List, Optional
from app.domain.entities.user_entity import UserEntity as User
from app.presentation.api.deps import require_admin, require_user
from app.shared.dependencies import (
    get_categories_use_case,
    get_category_by_id_use_case,
    create_category_use_case,
    update_category_use_case,
    delete_category_use_case,
    get_category_products_use_case,
)
from app.application.use_case.category.get_categories_usecase import GetCategoriesUseCase
from app.application.use_case.category.get_category_by_id_usecase import GetCategoryByIdUseCase
from app.application.use_case.category.create_category_usecase import CreateCategoryUseCase
from app.application.use_case.category.update_category_usecase import UpdateCategoryUseCase
from app.application.use_case.category.delete_category_usecase import DeleteCategoryUseCase
from app.application.use_case.category.get_category_products_usecase import GetCategoryProductsUseCase
from app.application.dto.category_dto import CategoryCreate, CategoryOut, CategoryPaginationOut

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("/", response_model=CategoryPaginationOut)
def getAll_category(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    use_case: GetCategoriesUseCase = Depends(get_categories_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/{category_id}", response_model=CategoryOut)
def get_category_id(
    category_id: int,
    use_case: GetCategoryByIdUseCase = Depends(get_category_by_id_use_case),
):
    return use_case.execute(id=category_id)


@router.post("/", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    category_in: CategoryCreate,
    use_case: CreateCategoryUseCase = Depends(create_category_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(name=category_in.name)


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    category_in: CategoryCreate,
    use_case: UpdateCategoryUseCase = Depends(update_category_use_case),
    current_admin: User = Depends(require_admin),
):
    return use_case.execute(id=category_id, name=category_in.name)


@router.delete("/{category_id}", status_code=status.HTTP_200_OK)
def delete_category(
    category_id: int,
    use_case: DeleteCategoryUseCase = Depends(delete_category_use_case),
    current_admin: User = Depends(require_admin),
):
    use_case.execute(id=category_id)
    return {"message": "Xóa danh mục thành công"}


@router.get("/{category_id}/products")
def get_products_by_category(
    category_id: int,
    use_case: GetCategoryProductsUseCase = Depends(get_category_products_use_case),
    current_user: User = Depends(require_user),
):
    return use_case.execute(id=category_id)
