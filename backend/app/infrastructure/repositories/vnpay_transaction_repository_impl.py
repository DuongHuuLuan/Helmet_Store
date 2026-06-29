from typing import Any

from sqlalchemy.orm import Session

from app.domain.repositories.vnpay_transaction_repository import VnPayTransactionRepository
from app.infrastructure.database.models.vnpay import VnPayTransaction


class VnPayTransactionRepositoryImpl(VnPayTransactionRepository):
    def __init__(self, db: Session):
        self.db = db

    def create(self, data: dict) -> Any:
        model = VnPayTransaction(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return model

    def get_by_order_id(self, order_id: int) -> list[Any]:
        return (
            self.db.query(VnPayTransaction)
            .filter(VnPayTransaction.order_id == order_id)
            .all()
        )
