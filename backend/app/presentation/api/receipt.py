from typing import Optional
from fastapi import APIRouter, Depends, status
from app.application.dto.receipt_dto import ReceiptCreate, ReceiptOut, ReceiptPaginationOut
from app.domain.entities.user_entity import UserEntity as User
from app.presentation.api.deps import require_admin
from app.shared.dependencies import (
    get_receipts_use_case,
    get_receipt_use_case,
    get_create_receipt_use_case,
    get_confirm_receipt_use_case,
    get_cancel_receipt_use_case,
)
from app.application.use_case.receipt.get_receipts_usecase import GetReceiptsUseCase
from app.application.use_case.receipt.get_receipt_usecase import GetReceiptUseCase
from app.application.use_case.receipt.create_receipt_usecase import CreateReceiptUseCase
from app.application.use_case.receipt.confirm_receipt_usecase import ConfirmReceiptUseCase
from app.application.use_case.receipt.cancel_receipt_usecase import CancelReceiptUseCase

router = APIRouter(prefix="/receipts", tags=["Receipt"])


@router.get("/", response_model=ReceiptPaginationOut)
def get_all_receipts(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    current_admin: User = Depends(require_admin),
    use_case: GetReceiptsUseCase = Depends(get_receipts_use_case),
):
    return use_case.execute(page=page, per_page=per_page, keyword=q)


@router.get("/{receipt_id}", response_model=ReceiptOut)
def get_receipt(
    receipt_id: int,
    current_admin: User = Depends(require_admin),
    use_case: GetReceiptUseCase = Depends(get_receipt_use_case),
):
    return use_case.execute(receipt_id)


@router.post("/", response_model=ReceiptOut, status_code=status.HTTP_201_CREATED)
def create_receipt(
    receipt_in: ReceiptCreate,
    current_admin: User = Depends(require_admin),
    use_case: CreateReceiptUseCase = Depends(get_create_receipt_use_case),
):
    return use_case.execute(receipt_in)


@router.post("/{receipt_id}/confirm", response_model=ReceiptOut)
def confirm_receipt(
    receipt_id: int,
    current_admin: User = Depends(require_admin),
    use_case: ConfirmReceiptUseCase = Depends(get_confirm_receipt_use_case),
):
    return use_case.execute(receipt_id)


@router.post("/{receipt_id}/cancel", response_model=ReceiptOut)
def cancel_receipt(
    receipt_id: int,
    current_admin: User = Depends(require_admin),
    use_case: CancelReceiptUseCase = Depends(get_cancel_receipt_use_case),
):
    return use_case.execute(receipt_id)


@router.post("/{receipt_id}/approve", response_model=ReceiptOut)
def approve_receipt(
    receipt_id: int,
    current_admin: User = Depends(require_admin),
    use_case: ConfirmReceiptUseCase = Depends(get_confirm_receipt_use_case),
):
    return use_case.execute(receipt_id)


@router.post("/{receipt_id}/reject", response_model=ReceiptOut)
def reject_receipt(
    receipt_id: int,
    current_admin: User = Depends(require_admin),
    use_case: CancelReceiptUseCase = Depends(get_cancel_receipt_use_case),
):
    return use_case.execute(receipt_id)
