from fastapi import APIRouter, Depends, status

from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.design_dto import (
    DesignCreate,
    DesignListOut,
    DesignOrderIn,
    DesignOrderOut,
    DesignOut,
    DesignShareOut,
    DesignUpdate,
)
from app.shared.dependencies import (
    get_create_design_use_case,
    get_update_design_use_case,
    get_designs_use_case,
    get_design_detail_use_case,
    get_create_share_link_use_case,
    get_order_design_use_case,
)
from app.application.use_case.design.create_design_usecase import CreateDesignUseCase
from app.application.use_case.design.update_design_usecase import UpdateDesignUseCase
from app.application.use_case.design.get_designs_usecase import GetDesignsUseCase
from app.application.use_case.design.get_design_detail_usecase import GetDesignDetailUseCase
from app.application.use_case.design.create_share_link_usecase import CreateShareLinkUseCase
from app.application.use_case.design.order_design_usecase import OrderDesignUseCase

router = APIRouter(prefix="/designs", tags=["Designs"])


@router.post("/", response_model=DesignOut, status_code=status.HTTP_201_CREATED)
def create_design(
    design_in: DesignCreate,
    current_user: User = Depends(require_user),
    use_case: CreateDesignUseCase = Depends(get_create_design_use_case),
):
    return use_case.execute(current_user.id, design_in)


@router.put("/{design_id}", response_model=DesignOut)
def update_design(
    design_id: int,
    design_in: DesignUpdate,
    current_user: User = Depends(require_user),
    use_case: UpdateDesignUseCase = Depends(get_update_design_use_case),
):
    return use_case.execute(design_id, current_user.id, design_in)


@router.get("/my-designs", response_model=DesignListOut)
def get_my_designs(
    current_user: User = Depends(require_user),
    use_case: GetDesignsUseCase = Depends(get_designs_use_case),
):
    designs = use_case.execute(current_user.id)
    return DesignListOut(items=designs)


@router.get("/{design_id}", response_model=DesignOut)
def get_design_detail(
    design_id: int,
    current_user: User = Depends(require_user),
    use_case: GetDesignDetailUseCase = Depends(get_design_detail_use_case),
):
    return use_case.execute(design_id, current_user.id)


@router.post("/{design_id}/share", response_model=DesignShareOut)
def create_design_share_link(
    design_id: int,
    current_user: User = Depends(require_user),
    use_case: CreateShareLinkUseCase = Depends(get_create_share_link_use_case),
):
    return use_case.execute(design_id, current_user.id)


@router.post("/{design_id}/order", response_model=DesignOrderOut)
def order_design(
    design_id: int,
    order_in: DesignOrderIn,
    current_user: User = Depends(require_user),
    use_case: OrderDesignUseCase = Depends(get_order_design_use_case),
):
    return use_case.execute(current_user.id, design_id, order_in)
