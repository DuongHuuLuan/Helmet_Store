from app.domain.repositories.receipt_repository import ReceiptRepository


class CancelReceiptUseCase:
    def __init__(self, repo: ReceiptRepository):
        self.repo = repo

    def execute(self, receipt_id: int) -> dict:
        return self.repo.cancel_receipt(receipt_id)
