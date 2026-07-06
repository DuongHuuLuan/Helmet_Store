from fastapi import APIRouter, Depends, status, HTTPException
from app.presentation.api.deps import require_admin
from typing import Optional
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.distributor_dto import DistributorCreate, DistributorOut, DistributorPaginationOut
from app.shared.dependencies import (
    get_distributors_use_case,
    get_distributor_use_case,
    get_create_distributor_use_case,
    get_update_distributor_use_case,
    get_delete_distributor_use_case,
)
from app.application.use_case.distributor.get_distributors_usecase import GetDistributorsUseCase
from app.application.use_case.distributor.get_distributor_usecase import GetDistributorUseCase
from app.application.use_case.distributor.create_distributor_usecase import CreateDistributorUseCase
from app.application.use_case.distributor.update_distributor_usecase import UpdateDistributorUseCase
from app.application.use_case.distributor.delete_distributor_usecase import DeleteDistributorUseCase

router = APIRouter(prefix="/distributors", tags=["Distributors"])


@router.get("/", response_model=DistributorPaginationOut)
def get_all(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    current_admin: User = Depends(require_admin),
    use_case: GetDistributorsUseCase = Depends(get_distributors_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/{distributor_id}", response_model=DistributorOut)
def get_id(
    distributor_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetDistributorUseCase = Depends(get_distributor_use_case),
):
    return use_case.execute(distributor_id)


@router.post("/", response_model=DistributorOut, status_code=status.HTTP_201_CREATED)
def create_distributor(
    distributor_in: DistributorCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreateDistributorUseCase = Depends(get_create_distributor_use_case),
):
    return use_case.execute(distributor_in)


@router.put("/{distributor_id}", response_model=DistributorOut)
def update_distributor(
    distributor_id: int,
    distributor_in: DistributorCreate,
    current_admin: User = Depends(require_admin),
    use_case: UpdateDistributorUseCase = Depends(get_update_distributor_use_case),
):
    return use_case.execute(distributor_id, distributor_in)


@router.delete("/{distributor_id}", status_code=status.HTTP_200_OK)
def delete_distributor(
    distributor_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeleteDistributorUseCase = Depends(get_delete_distributor_use_case),
):
    return use_case.execute(distributor_id)
