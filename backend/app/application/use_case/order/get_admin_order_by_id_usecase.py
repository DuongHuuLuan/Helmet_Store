from fastapi import HTTPException

from app.domain.repositories.order_repository import OrderRepository


class GetAdminOrderByIdUseCase:
    def __init__(self, order_repo: OrderRepository):
        self.order_repo = order_repo

    def execute(self, order_id: int):
        order = self.order_repo.get_admin_order_by_id(order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
        return order
