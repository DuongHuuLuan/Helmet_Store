from fastapi import APIRouter, Depends, status
from typing import Optional

from app.presentation.api.deps import require_admin
from app.domain.entities.user_entity import UserEntity as User
from app.application.dto.order_dto import (
    PaymentMethodOut,
    PaymentMethodCreate,
    PaymentMethodUpdate,
    PaymentMethodPaginationOut,
)
from app.application.use_case.payment.get_payment_methods_usecase import GetPaymentMethodsUseCase
from app.application.use_case.payment.get_payment_methods_admin_usecase import GetPaymentMethodsAdminUseCase
from app.application.use_case.payment.get_payment_method_by_id_usecase import GetPaymentMethodByIdUseCase
from app.application.use_case.payment.create_payment_method_usecase import CreatePaymentMethodUseCase
from app.application.use_case.payment.update_payment_method_usecase import UpdatePaymentMethodUseCase
from app.application.use_case.payment.delete_payment_method_usecase import DeletePaymentMethodUseCase
from app.shared.dependencies import (
    get_payment_methods_use_case,
    get_payment_methods_admin_use_case,
    get_create_payment_method_use_case,
    get_update_payment_method_use_case,
    get_delete_payment_method_use_case,
    get_payment_method_by_id_use_case,
)

router = APIRouter(prefix="/payment", tags=["Payment Method"])


@router.get("/", response_model=list[PaymentMethodOut])
def get_payment_methods(
    use_case: GetPaymentMethodsUseCase = Depends(get_payment_methods_use_case),
):
    return use_case.execute()


# --- Admin ---

@router.get("/admin", response_model=PaymentMethodPaginationOut)
def get_payment_methods_admin(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    current_admin: User = Depends(require_admin),
    use_case: GetPaymentMethodsAdminUseCase = Depends(get_payment_methods_admin_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/admin/{payment_id}", response_model=PaymentMethodOut)
def get_payment_method_id(
    payment_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetPaymentMethodByIdUseCase = Depends(get_payment_method_by_id_use_case),
):
    return use_case.execute(payment_id)


@router.post("/admin", response_model=PaymentMethodOut, status_code=status.HTTP_201_CREATED)
def create_payment_method(
    payment_in: PaymentMethodCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreatePaymentMethodUseCase = Depends(get_create_payment_method_use_case),
):
    return use_case.execute(payment_in.model_dump())


@router.put("/admin/{payment_id}", response_model=PaymentMethodOut)
def update_payment_method(
    payment_id: int,
    payment_in: PaymentMethodUpdate,
    current_admin: User = Depends(require_admin),
    use_case: UpdatePaymentMethodUseCase = Depends(get_update_payment_method_use_case),
):
    return use_case.execute(payment_id, payment_in.model_dump(exclude_unset=True))


@router.delete("/admin/{payment_id}", status_code=status.HTTP_200_OK)
def delete_payment_method(
    payment_id: int,
    current_admin: User = Depends(require_admin),
    use_case: DeletePaymentMethodUseCase = Depends(get_delete_payment_method_use_case),
):
    return use_case.execute(payment_id)
