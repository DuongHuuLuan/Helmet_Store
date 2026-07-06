from fastapi import HTTPException, status
from app.domain.repositories.payment_method_repository import PaymentMethodRepository


class GetPaymentMethodByIdUseCase:
    def __init__(self, repo: PaymentMethodRepository):
        self.repo = repo

    def execute(self, payment_id: int) -> dict:
        entity = self.repo.get_by_id(payment_id)
        if not entity:
            raise HTTPException(status_code=404, detail="Không tìm thấy phương thức thanh toán")

        return {"id": entity.id, "name": entity.name, "can_delete": entity.can_delete}
