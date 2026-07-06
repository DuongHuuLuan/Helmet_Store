from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.infrastructure.database.session import get_db
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.product_dto import ProductQuantityOut
from app.application.dto.warehouse_dto import (
    WarehouseCreate,
    WarehouseDetailPaginationOut,
    WarehouseOut,
    WarehousePaginationOut,
)
from app.infrastructure.repositories.warehouse_repository_impl import WarehouseRepositoryImpl
from app.presentation.api.deps import require_admin
from app.shared.dependencies import (
    get_warehouses_use_case,
    get_warehouse_use_case,
    get_warehouse_detail_use_case,
    get_create_warehouse_use_case,
    get_update_warehouse_use_case,
    get_delete_warehouse_use_case,
)
from app.application.use_case.warehouse.get_warehouses_usecase import GetWarehousesUseCase
from app.application.use_case.warehouse.get_warehouse_usecase import GetWarehouseUseCase
from app.application.use_case.warehouse.get_warehouse_detail_usecase import GetWarehouseDetailUseCase
from app.application.use_case.warehouse.create_warehouse_usecase import CreateWarehouseUseCase
from app.application.use_case.warehouse.update_warehouse_usecase import UpdateWarehouseUseCase
from app.application.use_case.warehouse.delete_warehouse_usecase import DeleteWarehouseUseCase

router = APIRouter(prefix="/warehouses", tags=["Warehouse"])


@router.get("/", response_model=WarehousePaginationOut)
def get_all(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    use_case: GetWarehousesUseCase = Depends(get_warehouses_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/product-quantity", response_model=ProductQuantityOut)
def get_product_quantity(
    product_id: int = Query(..., description="ID của sản phẩm"),
    size_id: int = Query(..., description="ID của kích thước"),
    color_id: int = Query(..., description="ID của màu sắc"),
    db: Session = Depends(get_db),
):
    quantity = WarehouseRepositoryImpl(db).get_total_stock(
        product_id=product_id, size_id=size_id, color_id=color_id
    )
    return {
        "product_id": product_id,
        "size_id": size_id,
        "color_id": color_id,
        "total_quantity": quantity,
    }


@router.get("/{warehouse_id}", response_model=WarehouseOut)
def get_warehouse(
    warehouse_id: int,
    use_case: GetWarehouseUseCase = Depends(get_warehouse_use_case),
):
    return use_case.execute(warehouse_id=warehouse_id)


@router.get("/{warehouse_id}/details", response_model=WarehouseDetailPaginationOut)
def get_warehouse_detail(
    warehouse_id: int,
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    category_id: Optional[int] = None,
    use_case: GetWarehouseDetailUseCase = Depends(get_warehouse_detail_use_case),
):
    return use_case.execute(
        warehouse_id=warehouse_id,
        page=page,
        per_page=per_page,
        keyword=q,
        category_id=category_id,
    )


@router.post("/", response_model=WarehouseOut, status_code=status.HTTP_201_CREATED)
def create_warehouse(
    warehouse_in: WarehouseCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreateWarehouseUseCase = Depends(get_create_warehouse_use_case),
):
    return use_case.execute(warehouse_in)


@router.put("/{warehouse_id}", response_model=WarehouseOut)
def update_warehouse(
    warehouse_id: int,
    warehouse_in: WarehouseCreate,
    current_admin: User = Depends(require_admin),
    use_case: UpdateWarehouseUseCase = Depends(get_update_warehouse_use_case),
):
    return use_case.execute(warehouse_id, warehouse_in)


@router.delete("/{warehouse_id}")
def delete_warehouse(
    warehouse_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeleteWarehouseUseCase = Depends(get_delete_warehouse_use_case),
):
    return use_case.execute(warehouse_id)
