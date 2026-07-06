from app.domain.entities.vnpay_transaction_entity import VnPayTransactionEntity


class VnPayTransactionMapper:
    @staticmethod
    def to_entity(model) -> VnPayTransactionEntity:
        return VnPayTransactionEntity(
            id=model.id,
            order_id=model.order_id,
            txn_ref=model.txn_ref,
            amount=model.amount,
            response_code=model.response_code,
            status=model.status,
            transaction_no=model.transaction_no,
            bank_code=model.bank_code,
            pay_date=model.pay_date,
            message=model.message,
            created_at=model.created_at,
        )
