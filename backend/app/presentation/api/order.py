from io import BytesIO
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import StreamingResponse

from app.presentation.api.deps import require_user, require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.order_dto import (
    OrderCreate,
    OrderOut,
    OrderPaginationOut,
    OrderRejectIn,
    OrderStatusUpdate,
)
from app.application.dto.production_dto import OrderProductionOut
from app.shared.dependencies import (
    get_create_order_use_case,
    get_user_orders_use_case,
    get_user_order_by_id_use_case,
    get_admin_orders_use_case,
    get_admin_order_by_id_use_case,
    get_cancel_order_use_case,
    get_update_order_status_use_case,
    get_approve_order_use_case,
    get_reject_order_use_case,
    get_confirm_delivery_use_case,
    get_order_production_use_case,
    get_export_order_production_use_case,
)
from app.application.use_case.order.create_order_usecase import CreateOrderUseCase
from app.application.use_case.order.get_user_orders_usecase import GetUserOrdersUseCase
from app.application.use_case.order.get_user_order_by_id_usecase import GetUserOrderByIdUseCase
from app.application.use_case.order.get_admin_orders_usecase import GetAdminOrdersUseCase
from app.application.use_case.order.get_admin_order_by_id_usecase import GetAdminOrderByIdUseCase
from app.application.use_case.order.cancel_order_usecase import CancelOrderUseCase
from app.application.use_case.order.update_order_status_usecase import UpdateOrderStatusUseCase
from app.application.use_case.order.approve_order_usecase import ApproveOrderUseCase
from app.application.use_case.order.reject_order_usecase import RejectOrderUseCase
from app.application.use_case.order.confirm_delivery_usecase import ConfirmDeliveryUseCase
from app.application.use_case.order.get_order_production_usecase import GetOrderProductionUseCase
from app.application.use_case.order.export_order_production_usecase import ExportOrderProductionUseCase


router = APIRouter(prefix="/orders", tags=["Order"])


@router.post("/", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    order_in: OrderCreate,
    current_user: User = Depends(require_user),
    use_case: CreateOrderUseCase = Depends(get_create_order_use_case),
):
    return use_case.execute(current_user.id, order_in)


# --- Admin ---

@router.get("/", response_model=OrderPaginationOut)
def get_admin_orders(
    page: int = 1,
    per_page: Optional[int] = None,
    q: Optional[str] = None,
    status: Optional[str] = None,
    current_admin: User = Depends(require_admin),
    use_case: GetAdminOrdersUseCase = Depends(get_admin_orders_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q, status_filter=status)


@router.get("/admin/{order_id}", response_model=OrderOut)
def get_admin_order_detail(
    order_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetAdminOrderByIdUseCase = Depends(get_admin_order_by_id_use_case),
):
    return use_case.execute(order_id)


@router.get("/admin/{order_id}/production", response_model=OrderProductionOut)
def get_order_production(
    order_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetOrderProductionUseCase = Depends(get_order_production_use_case),
):
    return use_case.execute(order_id)


@router.get("/admin/{order_id}/production/export")
def export_order_production(
    order_id: int,
    format: str = Query(default="pdf", pattern="^(pdf|svg)$"),
    dpi: int = Query(default=300, ge=72, le=600),
    current_admin: User = Depends(require_admin),
    use_case: ExportOrderProductionUseCase = Depends(get_export_order_production_use_case),
):
    file_bytes, media_type, filename = use_case.execute(
        order_id=order_id, export_format=format, dpi=dpi,
    )
    return StreamingResponse(
        BytesIO(file_bytes),
        media_type=media_type,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# --- User ---

@router.get("/history", response_model=list[OrderOut])
def get_order_history(
    current_user: User = Depends(require_user),
    use_case: GetUserOrdersUseCase = Depends(get_user_orders_use_case),
):
    return use_case.execute(current_user.id)


@router.get("/{order_id}", response_model=OrderOut)
def get_order_details(
    order_id: int,
    current_user: User = Depends(require_user),
    use_case: GetUserOrderByIdUseCase = Depends(get_user_order_by_id_use_case),
):
    return use_case.execute(order_id, current_user.id)


@router.post("/{order_id}/cancel")
def cancel_order(
    order_id: int,
    current_user: User = Depends(require_user),
    use_case: CancelOrderUseCase = Depends(get_cancel_order_use_case),
):
    return use_case.execute(order_id, current_user.id)


@router.put("/{order_id}/status", response_model=OrderOut)
def update_status(
    order_id: int,
    status_data: OrderStatusUpdate,
    current_admin: User = Depends(require_admin),
    use_case: UpdateOrderStatusUseCase = Depends(get_update_order_status_use_case),
):
    return use_case.execute(order_id, status_data.status)


@router.post("/{order_id}/approve", response_model=OrderOut)
def approve_order(
    order_id: int,
    current_admin: User = Depends(require_admin),
    use_case: ApproveOrderUseCase = Depends(get_approve_order_use_case),
):
    return use_case.execute(order_id, current_admin.id)


@router.post("/{order_id}/reject", response_model=OrderOut)
def reject_order(
    order_id: int,
    payload: OrderRejectIn,
    current_admin: User = Depends(require_admin),
    use_case: RejectOrderUseCase = Depends(get_reject_order_use_case),
):
    return use_case.execute(order_id, current_admin.id, payload.reason)


@router.post("/{order_id}/confirm-delivery", response_model=OrderOut)
def confirm_delivery(
    order_id: int,
    current_user: User = Depends(require_user),
    use_case: ConfirmDeliveryUseCase = Depends(get_confirm_delivery_use_case),
):
    return use_case.execute(order_id, current_user.id)
