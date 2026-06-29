from app.domain.repositories.cart_repository import CartRepository


class GetCartUseCase:
    def __init__(self, cart_repo: CartRepository):
        self.cart_repo = cart_repo

    def execute(self, user_id: int) -> dict:
        return self.cart_repo.get_cart_response(user_id)
