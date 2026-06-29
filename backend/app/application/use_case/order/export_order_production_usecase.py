from datetime import datetime

from fastapi import HTTPException, status

from app.domain.repositories.order_repository import OrderRepository


class ExportOrderProductionUseCase:
    def __init__(self, order_repo: OrderRepository):
        self._order_repo = order_repo

    def execute(self, order_id: int, export_format: str, dpi: int = 300) -> tuple[bytes, str, str]:
        from app.application.production.snapshot_service import ProductionSnapshotService
        from app.application.production.export_service import ProductionExportService
        order = self._order_repo.get_by_id_with_details(order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        payload = ProductionSnapshotService.build_order_production_payload(order)
        safe_format = (export_format or "").strip().lower()
        timestamp = datetime.now().strftime("%Y%m%d-%H%M")
        if safe_format == "pdf":
            file_bytes = ProductionExportService._render_pdf(payload, dpi=dpi)
            return (
                file_bytes,
                "application/pdf",
                f"order-{order_id}-production-{timestamp}.pdf",
            )
        if safe_format == "svg":
            file_bytes = ProductionExportService._render_svg(payload).encode("utf-8")
            return (
                file_bytes,
                "image/svg+xml",
                f"order-{order_id}-production-{timestamp}.svg",
            )
        raise HTTPException(status_code=400, detail="Unsupported export format")
