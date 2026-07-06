from app.domain.repositories.payment_method_repository import PaymentMethodRepository


class GetPaymentMethodsUseCase:
    def __init__(self, repo: PaymentMethodRepository):
        self.repo = repo

    def execute(self) -> list[dict]:
        entities = self.repo.get_all_active()
        return [{"id": e.id, "name": e.name, "can_delete": True} for e in entities]
