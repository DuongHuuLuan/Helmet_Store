from fastapi import HTTPException, status

from app.domain.repositories.receipt_repository import ReceiptRepository
from app.infrastructure.database.models.receipt import ReceiptStatus
from app.application.dto.receipt_dto import ReceiptCreate


class CreateReceiptUseCase:
    def __init__(self, repo: ReceiptRepository):
        self.repo = repo

    def execute(self, receipt_in: ReceiptCreate) -> dict:
        if not receipt_in.details:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Chi tiết phiếu nhập trống",
            )

        for item in receipt_in.details:
            if item.size_id is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Vui lòng chọn kích thước",
                )

        data = {
            "warehouse_id": receipt_in.warehouse_id,
            "distributor_id": receipt_in.distributor_id,
            "status": ReceiptStatus.PENDING,
        }
        details_data = [
            {
                "product_id": item.product_id,
                "color_id": item.color_id,
                "size_id": item.size_id,
                "quantity": item.quantity,
                "purchase_price": item.purchase_price,
            }
            for item in receipt_in.details
        ]
        return self.repo.create_with_details(data, details_data)
