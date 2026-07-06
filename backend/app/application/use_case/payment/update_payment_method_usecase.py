from app.domain.repositories.payment_method_repository import PaymentMethodRepository


class UpdatePaymentMethodUseCase:
    def __init__(self, repo: PaymentMethodRepository):
        self.repo = repo

    def execute(self, payment_id: int, data: dict) -> dict:
        entity = self.repo.update(payment_id, data)
        return {"id": entity.id, "name": entity.name, "can_delete": True}
