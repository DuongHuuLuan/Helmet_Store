from app.domain.entities.payment_method_entity import PaymentMethodEntity


class PaymentMethodMapper:
    @staticmethod
    def to_entity(model) -> PaymentMethodEntity:
        return PaymentMethodEntity(
            id=model.id,
            name=model.name,
        )
