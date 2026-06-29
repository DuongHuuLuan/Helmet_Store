from datetime import datetime
from typing import List

from sqlalchemy.orm import Session

from app.presentation.api.utils import format_dashboard_meta, get_status_tag, get_status_tone
from app.infrastructure.database.models import Order, Receipt


class GetDashboardActivityUseCase:
    def __init__(self, db: Session):
        self._db = db

    def execute(self, limit: int = 6) -> List[dict]:
        if limit < 1:
            limit = 1
        if limit > 20:
            limit = 20

        orders = (
            self._db.query(Order)
            .order_by(Order.created_at.desc())
            .limit(limit)
            .all()
        )
        receipts = (
            self._db.query(Receipt)
            .order_by(Receipt.created_at.desc())
            .limit(limit)
            .all()
        )

        items = []
        for order in orders:
            items.append({
                "created_at": order.created_at,
                "title": f"Đơn hàng #{order.id}",
                "tag": get_status_tag(order.status),
                "tone": get_status_tone(order.status),
            })

        for receipt in receipts:
            items.append({
                "created_at": receipt.created_at,
                "title": f"Phiếu nhập #{receipt.id}",
                "tag": get_status_tag(receipt.status),
                "tone": get_status_tone(receipt.status),
            })

        items.sort(
            key=lambda item: item.get("created_at") or datetime.min,
            reverse=True,
        )

        output = []
        for item in items[:limit]:
            output.append({
                "title": item["title"],
                "meta": format_dashboard_meta(item.get("created_at")),
                "tag": item["tag"],
                "tone": item["tone"],
            })

        return output
