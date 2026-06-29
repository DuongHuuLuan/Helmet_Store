import io
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas

from app.application.dto.statistics_dto import StatisticsFilterParams
from app.domain.repositories.statistics_repository import StatisticsRepository


class StatisticsExportService:
    RANGE_LABELS = {
        "7d": "7 ngày gần nhất",
        "30d": "30 ngày gần nhất",
        "month": "Tháng này",
        "quarter": "Quý này",
    }

    _fonts_registered = False
    _font_regular = "Helvetica"
    _font_bold = "Helvetica-Bold"

    @staticmethod
    def export_pdf(repo: StatisticsRepository, filters: StatisticsFilterParams) -> tuple[bytes, str]:
        snapshot = StatisticsExportService._build_snapshot(repo, filters)
        pdf_bytes = StatisticsExportService._render_pdf(snapshot)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M")
        filename = f"thong-ke-{filters.scope.value}-{timestamp}.pdf"
        return pdf_bytes, filename

    @staticmethod
    def _build_snapshot(repo: StatisticsRepository, filters: StatisticsFilterParams) -> dict:
        return {
            "overview": repo.get_overview(filters),
            "revenue_series": repo.get_revenue_series(filters),
            "order_mix": repo.get_order_mix(filters),
            "top_products": repo.get_top_products(filters),
            "payment_mix": repo.get_payment_mix(filters),
            "reviews_summary": repo.get_reviews_summary(filters),
            "alerts": repo.get_alerts(filters),
        }

    @staticmethod
    def _render_pdf(snapshot: dict) -> bytes:
        buf = io.BytesIO()
        pdf = canvas.Canvas(buf, pagesize=A4)
        pdf.setTitle("Báo cáo thống kê")
        width, height = A4
        margin = 20 * mm
        y = height - margin

        def write_line(text, size=10, bold=False, indent=0):
            nonlocal y
            pdf.setFont(
                StatisticsExportService._font_bold if bold else StatisticsExportService._font_regular,
                size,
            )
            pdf.drawString(margin + indent, y, text)
            y -= size * 0.6

        def check_page():
            nonlocal y
            if y < margin:
                pdf.showPage()
                y = height - margin

        write_line("BÁO CÁO THỐNG KÊ", 16, bold=True)
        y -= 4
        write_line(f"Ngày xuất: {datetime.now().strftime('%d/%m/%Y %H:%M')}", 8)
        y -= 8

        overview = snapshot.get("overview", {})
        write_line("TỔNG QUAN", 12, bold=True)
        write_line(f"Doanh thu: {overview.get('revenue', 0):,.0f} VNĐ", 10)
        write_line(f"Đơn hàng: {overview.get('orders', 0)}", 10)
        write_line(f"Giá trị TB: {overview.get('average_order_value', 0):,.2f} VNĐ", 10)
        write_line(f"Tỉ lệ hoàn thành: {overview.get('completion_rate', 0)}%", 10)
        y -= 8

        top_products = snapshot.get("top_products", {}).get("items", [])
        if top_products:
            check_page()
            write_line("TOP SẢN PHẨM", 12, bold=True)
            for item in top_products:
                write_line(f"  - {item.get('name')}: {item.get('sold')} cái, {item.get('revenue', 0):,.0f} VNĐ", 9)
            y -= 8

        order_mix = snapshot.get("order_mix", {}).get("items", [])
        if order_mix:
            check_page()
            write_line("CƠ CẤU ĐƠN HÀNG", 12, bold=True)
            for item in order_mix:
                write_line(f"  - {item.get('label')}: {item.get('count')} ({item.get('share')}%)", 9)
            y -= 8

        reviews = snapshot.get("reviews_summary", {})
        if reviews.get("total_reviews", 0):
            check_page()
            write_line("ĐÁNH GIÁ", 12, bold=True)
            write_line(f"Tổng đánh giá: {reviews.get('total_reviews', 0)}", 10)
            write_line(f"Điểm TB: {reviews.get('average_rating', 0)} / 5", 10)
            write_line(f"Chưa phản hồi: {reviews.get('pending_replies', 0)}", 10)

        pdf.save()
        buf.seek(0)
        return buf.getvalue()
