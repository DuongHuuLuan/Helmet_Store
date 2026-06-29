from app.domain.entities.cart_entity import CartEntity
from app.infrastructure.database.models.cart import Cart


class CartMapper:
    @staticmethod
    def to_entity(model: Cart) -> CartEntity:
        return CartEntity(
            id=model.id,
            user_id=model.user_id,
        )

    @staticmethod
    def to_model(entity: CartEntity) -> Cart:
        return Cart(
            id=entity.id,
            user_id=entity.user_id,
        )
