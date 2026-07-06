from fastapi import HTTPException, status

from app.domain.repositories.receipt_repository import ReceiptRepository


class GetReceiptUseCase:
    def __init__(self, repo: ReceiptRepository):
        self.repo = repo

    def execute(self, receipt_id: int) -> dict:
        receipt = self.repo.get_by_id_with_details(receipt_id)
        if not receipt:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy phiếu nhập",
            )
        return receipt
