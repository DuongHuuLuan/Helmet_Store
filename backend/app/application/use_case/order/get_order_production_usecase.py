from fastapi import HTTPException, status

from app.domain.repositories.order_repository import OrderRepository


class GetOrderProductionUseCase:
    def __init__(self, order_repo: OrderRepository):
        self._order_repo = order_repo

    def execute(self, order_id: int) -> dict:
        from app.application.production.snapshot_service import ProductionSnapshotService
        order = self._order_repo.get_by_id_with_details(order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        return ProductionSnapshotService.build_order_production_payload(order)
