from app.domain.entities.order_entity import OrderEntity, OrderDetailEntity


class OrderMapper:
    @staticmethod
    def to_entity(model) -> OrderEntity:
        return OrderEntity(
            id=model.id,
            user_id=model.user_id,
            delivery_info_id=model.delivery_info_id,
            payment_method_id=model.payment_method_id,
            status=model.status.value if hasattr(model.status, 'value') else model.status,
            payment_status=model.payment_status.value if hasattr(model.payment_status, 'value') else model.payment_status,
            refund_support_status=model.refund_support_status.value if hasattr(model.refund_support_status, 'value') else model.refund_support_status,
            rejection_reason=model.rejection_reason,
            reviewed_by_admin_id=model.reviewed_by_admin_id,
            reviewed_at=model.reviewed_at,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_detail_entity(model) -> OrderDetailEntity:
        return OrderDetailEntity(
            id=model.id,
            order_id=model.order_id,
            product_detail_id=model.product_detail_id,
            design_id=model.design_id,
            quantity=model.quantity,
            price=model.price,
            design_snapshot_json=model.design_snapshot_json,
        )
