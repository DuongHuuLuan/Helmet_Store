from datetime import date, datetime, timedelta
from typing import Dict

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.infrastructure.database.models import (
    Category, Evaluate, Order, OrderDetail,
    PaymentMethod, Product, ProductDetail,
)
from app.infrastructure.database.models.order import OrderStatus
from app.application.dto.statistics_dto import (
    StatisticsFilterParams, StatisticsOrderStatus, StatisticsScope,
)
from app.domain.repositories.statistics_repository import StatisticsRepository


STATUS_LABELS = {
    OrderStatus.PENDING.value: "Chờ xác nhận",
    OrderStatus.SHIPPING.value: "Đang giao",
    OrderStatus.COMPLETED.value: "Hoàn tất",
    OrderStatus.CANCELLED.value: "Đã hủy",
}


class StatisticsRepositoryImpl(StatisticsRepository):

    def __init__(self, db: Session):
        self.db = db

    def get_overview(self, filters: StatisticsFilterParams) -> dict:
        total_orders = int(
            self._apply_order_filters(
                self.db.query(func.count(Order.id)),
                filters,
            ).scalar() or 0
        )
        revenue = self._to_float(
            self._apply_order_filters(
                self.db.query(func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0))
                .join(Order, Order.id == OrderDetail.order_id),
                filters,
                exclude_cancelled_when_all=True,
            ).scalar()
        )
        valid_orders = int(
            self._apply_order_filters(
                self.db.query(func.count(func.distinct(Order.id))),
                filters,
                exclude_cancelled_when_all=True,
            ).scalar() or 0
        )
        if filters.order_status == StatisticsOrderStatus.ALL:
            completed_orders = int(
                self._apply_date_range(
                    self.db.query(func.count(Order.id)).filter(Order.status == OrderStatus.COMPLETED),
                    Order.created_at, filters,
                ).scalar() or 0
            )
            completion_rate = round((completed_orders / total_orders) * 100) if total_orders else 0
        else:
            completion_rate = 100 if filters.order_status == StatisticsOrderStatus.COMPLETED and total_orders else 0
        return {
            "revenue": revenue,
            "orders": total_orders,
            "average_order_value": round(revenue / valid_orders, 2) if valid_orders else 0,
            "completion_rate": completion_rate,
            "pending_orders": self._count_orders_by_status(OrderStatus.PENDING, filters),
            "pending_reviews": self._get_pending_reviews_count(filters),
        }

    def get_revenue_series(self, filters: StatisticsFilterParams) -> dict:
        start_at, end_at = self._resolve_date_range(filters.range)
        rows = (
            self._apply_order_filters(
                self.db.query(
                    func.date(Order.created_at).label("bucket_date"),
                    func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0).label("revenue"),
                )
                .join(Order, Order.id == OrderDetail.order_id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(func.date(Order.created_at))
            .order_by(func.date(Order.created_at))
            .all()
        )
        daily_map: Dict[date, float] = {
            self._to_date(row.bucket_date): self._to_float(row.revenue) for row in rows
        }
        return {"items": self._build_revenue_points(filters.range, start_at, end_at, daily_map)}

    def get_order_mix(self, filters: StatisticsFilterParams) -> dict:
        rows = (
            self._apply_order_filters(
                self.db.query(Order.status.label("status"), func.count(Order.id).label("count")),
                filters,
            )
            .group_by(Order.status)
            .all()
        )
        total = sum(int(row.count or 0) for row in rows) or 1
        items = []
        for row in rows:
            status_value = row.status.value if hasattr(row.status, "value") else str(row.status)
            count = int(row.count or 0)
            items.append({
                "status": status_value,
                "label": STATUS_LABELS.get(status_value, status_value),
                "count": count,
                "share": round((count / total) * 100),
            })
        return {"items": items}

    def get_top_products(self, filters: StatisticsFilterParams) -> dict:
        rows = (
            self._apply_order_filters(
                self.db.query(
                    Product.name.label("name"),
                    func.coalesce(Category.name, "-").label("category"),
                    func.coalesce(func.sum(OrderDetail.quantity), 0).label("sold"),
                    func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0).label("revenue"),
                )
                .join(Order, Order.id == OrderDetail.order_id)
                .join(ProductDetail, ProductDetail.id == OrderDetail.product_detail_id)
                .join(Product, Product.id == ProductDetail.product_id)
                .outerjoin(Category, Category.id == Product.category_id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(Product.id, Product.name, Category.name)
            .order_by(func.sum(OrderDetail.quantity).desc(), func.sum(OrderDetail.price * OrderDetail.quantity).desc())
            .limit(5)
            .all()
        )
        items = []
        for row in rows:
            items.append({
                "name": row.name,
                "category": row.category or "-",
                "sold": int(row.sold or 0),
                "revenue": self._to_float(row.revenue),
                "note": "",
            })
        return {"items": items}

    def get_payment_mix(self, filters: StatisticsFilterParams) -> dict:
        revenue_expr = func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0)
        rows = (
            self._apply_order_filters(
                self.db.query(
                    func.coalesce(PaymentMethod.name, "Chưa chọn").label("method_name"),
                    func.count(func.distinct(Order.id)).label("count"),
                    revenue_expr.label("revenue"),
                )
                .select_from(Order)
                .outerjoin(PaymentMethod, PaymentMethod.id == Order.payment_method_id)
                .outerjoin(OrderDetail, OrderDetail.order_id == Order.id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(PaymentMethod.id, PaymentMethod.name)
            .order_by(func.count(func.distinct(Order.id)).desc(), revenue_expr.desc())
            .all()
        )
        total_orders = sum(int(row.count or 0) for row in rows) or 1
        items = []
        for row in rows:
            label = row.method_name or "Chưa chọn"
            count = int(row.count or 0)
            items.append({
                "method": self._to_key(label),
                "label": label,
                "count": count,
                "revenue": self._to_float(row.revenue),
                "share": round((count / total_orders) * 100),
            })
        return {"items": items}

    def get_reviews_summary(self, filters: StatisticsFilterParams) -> dict:
        summary = self._apply_review_filters(
            self.db.query(func.count(Evaluate.id).label("total_reviews"),
                          func.coalesce(func.avg(Evaluate.rate), 0).label("average_rating")),
            filters,
        ).first()
        distribution_rows = (
            self._apply_review_filters(
                self.db.query(Evaluate.rate.label("rate"), func.count(Evaluate.id).label("count")),
                filters,
            )
            .group_by(Evaluate.rate)
            .all()
        )
        total_reviews = int(summary.total_reviews or 0) if summary else 0
        rate_map = {int(row.rate or 0): int(row.count or 0) for row in distribution_rows if row.rate is not None}
        items = []
        for rate in range(5, 0, -1):
            count = rate_map.get(rate, 0)
            items.append({"rate": rate, "count": count, "share": round((count / total_reviews) * 100) if total_reviews else 0})
        return {
            "total_reviews": total_reviews,
            "average_rating": round(self._to_float(summary.average_rating), 1) if summary else 0.0,
            "pending_replies": self._get_pending_reviews_count(filters),
            "items": items,
        }

    def get_alerts(self, filters: StatisticsFilterParams) -> dict:
        pending_reviews = self._get_pending_reviews_count(filters)
        items = []
        include_review_alerts = filters.scope in (StatisticsScope.OVERVIEW, StatisticsScope.REVIEWS)
        include_order_alerts = filters.scope in (StatisticsScope.OVERVIEW, StatisticsScope.SALES)
        if pending_reviews and include_review_alerts:
            items.append({"title": f"{pending_reviews} đánh giá chưa phản hồi",
                          "text": "Nên xử lý sớm để tránh tồn động chăm sóc khách hàng.",
                          "action": "Đánh giá", "to": "/evaluates"})
        if include_order_alerts and filters.order_status == StatisticsOrderStatus.ALL:
            pending_orders = self._count_orders_by_status(OrderStatus.PENDING, filters)
            cancelled_orders = self._count_orders_by_status(OrderStatus.CANCELLED, filters)
            if pending_orders:
                items.append({"title": f"{pending_orders} đơn đang chờ xác nhận",
                              "text": "Nhóm đơn này ảnh hưởng trực tiếp đến tốc độ xử lý và giao hàng.",
                              "action": "Đơn hàng", "to": "/orders"})
            if cancelled_orders:
                items.append({"title": f"{cancelled_orders} đơn đã hủy cần theo dõi",
                              "text": "Nên kiểm tra nguyên nhân hủy để giảm tỉ lệ mất đơn.",
                              "action": "Đơn hàng", "to": "/orders"})
        elif include_order_alerts:
            selected_status = OrderStatus(filters.order_status.value)
            selected_orders = self._count_orders_by_status(selected_status, filters)
            if selected_orders:
                items.append({"title": f"{selected_orders} đơn ở trạng thái {STATUS_LABELS.get(selected_status.value, selected_status.value)}",
                              "text": "Đây là nhóm đơn hàng được lọc hiện tại để ưu tiên theo dõi.",
                              "action": "Đơn hàng", "to": "/orders"})
        return {"items": items}

    def _apply_order_filters(self, query, filters, exclude_cancelled_when_all=False):
        if filters.order_status == StatisticsOrderStatus.ALL:
            if exclude_cancelled_when_all:
                query = query.filter(Order.status != OrderStatus.CANCELLED)
        else:
            status = OrderStatus(filters.order_status.value)
            query = query.filter(Order.status == status)
        if filters.start_date:
            query = query.filter(Order.created_at >= filters.start_date)
        if filters.end_date:
            query = query.filter(Order.created_at <= filters.end_date)
        return query

    def _apply_review_filters(self, query, filters):
        start_date, end_date = self._resolve_date_range(filters.range)
        if start_date:
            query = query.filter(Evaluate.created_at >= start_date)
        if end_date:
            query = query.filter(Evaluate.created_at <= end_date)
        return query

    def _apply_date_range(self, query, date_column, filters):
        if filters.start_date:
            query = query.filter(date_column >= filters.start_date)
        if filters.end_date:
            query = query.filter(date_column <= filters.end_date)
        return query

    def _resolve_date_range(self, range_enum):
        today = date.today()
        if range_enum == StatisticsScope.DAY:
            return today, today + timedelta(days=1)
        if range_enum == StatisticsScope.WEEK:
            return today - timedelta(days=7), today + timedelta(days=1)
        if range_enum == StatisticsScope.MONTH:
            return today - timedelta(days=30), today + timedelta(days=1)
        if range_enum == StatisticsScope.QUARTER:
            return today - timedelta(days=90), today + timedelta(days=1)
        return today - timedelta(days=365), today + timedelta(days=1)

    def _build_revenue_points(self, range_enum, start_at, end_at, daily_map):
        items = []
        if range_enum in (StatisticsScope.DAY, StatisticsScope.WEEK, StatisticsScope.MONTH):
            current = start_at
            while current <= end_at:
                items.append({
                    "date": current.isoformat(),
                    "revenue": self._to_float(daily_map.get(current, 0)),
                })
                current += timedelta(days=1)
        else:
            current = start_at
            while current <= end_at:
                month_key = current.replace(day=1)
                month_revenue = sum(
                    self._to_float(v) for k, v in daily_map.items()
                    if k.year == month_key.year and k.month == month_key.month
                )
                items.append({
                    "date": month_key.isoformat(),
                    "revenue": month_revenue,
                })
                current = (month_key + timedelta(days=32)).replace(day=1)
        return items

    def _count_orders_by_status(self, status: OrderStatus, filters) -> int:
        query = self.db.query(func.count(Order.id)).filter(Order.status == status)
        if filters.start_date:
            query = query.filter(Order.created_at >= filters.start_date)
        if filters.end_date:
            query = query.filter(Order.created_at <= filters.end_date)
        return int(query.scalar() or 0)

    def _get_pending_reviews_count(self, filters) -> int:
        query = self.db.query(func.count(Evaluate.id)).filter(Evaluate.admin_reply.is_(None))
        start_at, end_at = self._resolve_date_range(filters.range)
        if start_at:
            query = query.filter(Evaluate.created_at >= start_at)
        if end_at:
            query = query.filter(Evaluate.created_at <= end_at)
        return int(query.scalar() or 0)

    @staticmethod
    def _to_float(value):
        return float(value or 0)

    @staticmethod
    def _to_date(value):
        return value.date() if hasattr(value, "date") else value

    @staticmethod
    def _to_key(value):
        return str(value).strip().lower().replace(" ", "_")
