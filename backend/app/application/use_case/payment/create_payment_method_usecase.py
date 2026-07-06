from app.domain.repositories.payment_method_repository import PaymentMethodRepository


class CreatePaymentMethodUseCase:
    def __init__(self, repo: PaymentMethodRepository):
        self.repo = repo

    def execute(self, data: dict) -> dict:
        entity = self.repo.create(data)
        return {"id": entity.id, "name": entity.name, "can_delete": True}
