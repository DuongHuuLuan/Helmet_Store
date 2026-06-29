from app.domain.entities.receipt_entity import ReceiptEntity, ReceiptDetailEntity


class ReceiptMapper:
    @staticmethod
    def to_entity(model) -> ReceiptEntity:
        return ReceiptEntity(
            id=model.id,
            warehouse_id=model.warehouse_id,
            distributor_id=model.distributor_id,
            status=model.status.value if hasattr(model.status, 'value') else model.status,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )


class ReceiptDetailMapper:
    @staticmethod
    def to_entity(model) -> ReceiptDetailEntity:
        return ReceiptDetailEntity(
            id=model.id,
            receipt_id=model.receipt_id,
            product_id=model.product_id,
            color_id=model.color_id,
            size_id=model.size_id,
            quantity=model.quantity,
            purchase_price=model.purchase_price,
        )
