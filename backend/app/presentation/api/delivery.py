from fastapi import APIRouter, Depends, HTTPException

from app.presentation.api.deps import require_user
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.order_dto import DeliveryInfoOut, DeliveryInfoBase
from app.application.use_case.delivery.create_delivery_usecase import CreateDeliveryUseCase
from app.application.use_case.delivery.get_my_deliveries_usecase import GetMyDeliveriesUseCase
from app.application.use_case.delivery.delete_delivery_usecase import DeleteDeliveryUseCase
from app.shared.dependencies import (
    get_create_delivery_use_case,
    get_my_deliveries_use_case,
    get_delete_delivery_use_case,
)

router = APIRouter(prefix="/delivery", tags=["Delivery Info"])


@router.post("/", response_model=DeliveryInfoOut)
def add_address(
    data: DeliveryInfoBase,
    current_user: User = Depends(require_user),
    use_case: CreateDeliveryUseCase = Depends(get_create_delivery_use_case),
):
    return use_case.execute(current_user.id, data.model_dump())


@router.get("/", response_model=list[DeliveryInfoOut])
def get_addresses(
    current_user: User = Depends(require_user),
    use_case: GetMyDeliveriesUseCase = Depends(get_my_deliveries_use_case),
):
    return use_case.execute(current_user.id)


@router.delete("/{delivery_id}")
def delete_address(
    delivery_id: int,
    current_user: User = Depends(require_user),
    use_case: DeleteDeliveryUseCase = Depends(get_delete_delivery_use_case),
):
    return use_case.execute(delivery_id, current_user.id)
