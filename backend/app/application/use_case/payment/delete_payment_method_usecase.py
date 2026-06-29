from app.domain.repositories.payment_method_repository import PaymentMethodRepository


class DeletePaymentMethodUseCase:
    def __init__(self, repo: PaymentMethodRepository):
        self.repo = repo

    def execute(self, payment_id: int) -> dict:
        self.repo.ensure_can_delete(payment_id)
        self.repo.delete(payment_id)
        return {"message": "Xóa phương thức thanh toán thành công"}
