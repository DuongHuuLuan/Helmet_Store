import base64
import html
import os
from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Any, Optional
from urllib.parse import urlparse

import httpx
from fastapi import HTTPException
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from sqlalchemy.orm import Session

from app.application.production.snapshot_service import ProductionSnapshotService


class ProductionExportService:
    PAGE_WIDTH_PT, PAGE_HEIGHT_PT = A4
    PAGE_WIDTH_MM = PAGE_WIDTH_PT / mm
    PAGE_HEIGHT_MM = PAGE_HEIGHT_PT / mm
    REPO_ROOT = Path(__file__).resolve().parents[3]
    PDF_FONT_REGULAR = "Helvetica"
    PDF_FONT_BOLD = "Helvetica-Bold"
    PDF_FONT_ITALIC = "Helvetica-Oblique"
    _PDF_FONTS_READY = False

    @staticmethod
    def _normalize_enum_text(value: Any) -> str:
        raw = str(value or "").strip()
        if not raw:
            return ""
        return raw.split(".")[-1].strip().lower()

    @staticmethod
    def _order_status_label(value: Any) -> str:
        normalized = ProductionExportService._normalize_enum_text(value)
        return {
            "pending": "Đang duyệt",
            "shipping": "Đang giao",
            "completed": "Hoàn thành",
            "cancelled": "Đã hủy",
        }.get(normalized, str(value or "-"))

    @staticmethod
    def _payment_status_label(value: Any) -> str:
        normalized = ProductionExportService._normalize_enum_text(value)
        return {
            "paid": "Đã thanh toán",
            "unpaid": "Chưa thanh toán",
        }.get(normalized, str(value or "-"))

    @staticmethod
    def _refund_support_label(value: Any) -> str:
        normalized = ProductionExportService._normalize_enum_text(value)
        return {
            "none": "Không yêu cầu",
            "contact_required": "Liên hệ chat để hoàn tiền",
            "resolved": "Đã xử lý hoàn tiền",
        }.get(normalized, str(value or "-"))

    @staticmethod
    def _position_label(value: Any) -> str:
        raw = str(value or "").strip()
        return {
            "Phia tren": "Phía trên",
            "Ben trai": "Bên trái",
            "Ben phai": "Bên phải",
            "Phia sau": "Phía sau",
            "Mat truoc": "Mặt trước",
            "Truoc phai": "Trước phải",
            "Truoc trai": "Trước trái",
        }.get(raw, raw or "-")

    @staticmethod
    def _sorted_views(item: dict[str, Any]) -> list[dict[str, Any]]:
        raw_views = [view for view in (item.get("views") or []) if isinstance(view, dict)]
        if not raw_views:
            return [
                {
                    "view_image_key": None,
                    "label": "Ảnh mặc định",
                    "base_image_url": item.get("base_image_url"),
                    "preview_image_url": item.get("preview_image_url"),
                    "layers": list(item.get("layers") or []),
                }
            ]

        return sorted(
            raw_views,
            key=lambda view: (
                ProductionSnapshotService._view_order(view.get("view_image_key")),
                str(view.get("view_image_key") or ""),
            ),
        )

    @staticmethod
    def _view_label(view: dict[str, Any]) -> str:
        label = str(view.get("label") or "").strip()
        if label:
            return ProductionExportService._position_label(label)
        fallback = ProductionSnapshotService._view_label(view.get("view_image_key"))
        return ProductionExportService._position_label(fallback or "Ảnh mặc định")

    @staticmethod
    def _resolve_view_base_image(
        item: dict[str, Any],
        view: dict[str, Any],
    ) -> Optional[str]:
        return (
            view.get("base_image_url")
            or view.get("preview_image_url")
            or item.get("base_image_url")
            or item.get("preview_image_url")
        )

    @staticmethod
    def _register_ttf_font(font_name: str, candidates: list[Path]) -> Optional[str]:
        for candidate in candidates:
            if not candidate.exists():
                continue
            if font_name not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(TTFont(font_name, str(candidate)))
            return font_name
        return None

    @staticmethod
    def _ensure_pdf_fonts() -> None:
        if ProductionExportService._PDF_FONTS_READY:
            return

        windows_font_dir = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"
        regular_font = ProductionExportService._register_ttf_font(
            "ProductionExportRegular",
            [
                ProductionExportService.REPO_ROOT / "backend" / "assets" / "fonts" / "DejaVuSans.ttf",
                windows_font_dir / "arial.ttf",
                windows_font_dir / "tahoma.ttf",
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
                Path("/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf"),
            ],
        )
        bold_font = ProductionExportService._register_ttf_font(
            "ProductionExportBold",
            [
                ProductionExportService.REPO_ROOT / "backend" / "assets" / "fonts" / "DejaVuSans-Bold.ttf",
                windows_font_dir / "arialbd.ttf",
                windows_font_dir / "tahomabd.ttf",
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
                Path("/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf"),
            ],
        )
        italic_font = ProductionExportService._register_ttf_font(
            "ProductionExportItalic",
            [
                ProductionExportService.REPO_ROOT / "backend" / "assets" / "fonts" / "DejaVuSans-Oblique.ttf",
                windows_font_dir / "ariali.ttf",
                windows_font_dir / "tahoma.ttf",
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf"),
                Path("/usr/share/fonts/truetype/liberation2/LiberationSans-Italic.ttf"),
            ],
        )

        if regular_font:
            ProductionExportService.PDF_FONT_REGULAR = regular_font
        if bold_font:
            ProductionExportService.PDF_FONT_BOLD = bold_font
        elif regular_font:
            ProductionExportService.PDF_FONT_BOLD = regular_font
        if italic_font:
            ProductionExportService.PDF_FONT_ITALIC = italic_font
        elif regular_font:
            ProductionExportService.PDF_FONT_ITALIC = regular_font

        ProductionExportService._PDF_FONTS_READY = True

    @staticmethod
    def _set_pdf_font(
        pdf: canvas.Canvas,
        size: float,
        *,
        bold: bool = False,
        italic: bool = False,
    ) -> None:
        ProductionExportService._ensure_pdf_fonts()
        font_name = ProductionExportService.PDF_FONT_REGULAR
        if bold:
            font_name = ProductionExportService.PDF_FONT_BOLD
        elif italic:
            font_name = ProductionExportService.PDF_FONT_ITALIC
        pdf.setFont(font_name, size)

    @staticmethod
    def get_order_production(db: Session, order_id: int) -> dict[str, Any]:
        from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl
        order = OrderRepositoryImpl(db).get_by_id_with_details(order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        return ProductionSnapshotService.build_order_production_payload(order)

    @staticmethod
    def export_order(
        db: Session,
        order_id: int,
        export_format: str,
        dpi: int = 300,
    ) -> tuple[bytes, str, str]:
        payload = ProductionExportService.get_order_production(db, order_id)
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

    @staticmethod
    def _load_image_asset(
        source: Optional[str],
        cache: dict[str, dict[str, Any]],
    ) -> Optional[dict[str, Any]]:
        if not source:
            return None

        cached = cache.get(source)
        if cached is not None:
            return cached

        raw_bytes = None
        mime_type = None

        try:
            if source.startswith("http://") or source.startswith("https://"):
                response = httpx.get(source, timeout=12.0, follow_redirects=True)
                response.raise_for_status()
                raw_bytes = response.content
                mime_type = response.headers.get("content-type")
            elif source.startswith("assets/"):
                asset_path = ProductionExportService.REPO_ROOT / "frontend" / "user" / source
                if asset_path.exists():
                    raw_bytes = asset_path.read_bytes()
                    mime_type = ProductionExportService._guess_mime_type(asset_path.suffix)
            else:
                file_path = Path(source)
                if file_path.exists():
                    raw_bytes = file_path.read_bytes()
                    mime_type = ProductionExportService._guess_mime_type(file_path.suffix)
        except Exception:
            raw_bytes = None
            mime_type = None

        if not raw_bytes:
            cache[source] = None
            return None

        try:
            reader = ImageReader(BytesIO(raw_bytes))
            width_px, height_px = reader.getSize()
        except Exception:
            cache[source] = None
            return None

        if not mime_type:
            parsed = urlparse(source)
            mime_type = ProductionExportService._guess_mime_type(Path(parsed.path).suffix)

        asset = {
            "bytes": raw_bytes,
            "mime_type": mime_type or "image/png",
            "reader": reader,
            "width_px": width_px,
            "height_px": height_px,
        }
        cache[source] = asset
        return asset

    @staticmethod
    def _guess_mime_type(extension: str) -> str:
        safe_extension = (extension or "").lower()
        if safe_extension in {".jpg", ".jpeg"}:
            return "image/jpeg"
        if safe_extension == ".webp":
            return "image/webp"
        if safe_extension == ".svg":
            return "image/svg+xml"
        return "image/png"

    @staticmethod
    def _draw_image_contain(
        pdf: canvas.Canvas,
        asset: Optional[dict[str, Any]],
        x_pt: float,
        y_pt: float,
        width_pt: float,
        height_pt: float,
    ) -> None:
        if not asset:
            pdf.saveState()
            pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
            pdf.setFillColor(colors.HexColor("#F9FAFB"))
            pdf.rect(x_pt, y_pt, width_pt, height_pt, stroke=1, fill=1)
            pdf.setFillColor(colors.HexColor("#6B7280"))
            ProductionExportService._set_pdf_font(pdf, 9)
            pdf.drawString(x_pt + 8, y_pt + height_pt - 14, "Không tải được ảnh")
            pdf.restoreState()
            return

        pdf.drawImage(
            asset["reader"],
            x_pt,
            y_pt,
            width=width_pt,
            height=height_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )

    @staticmethod
    def _draw_layer_preview(
        pdf: canvas.Canvas,
        layer: dict[str, Any],
        preview_x_pt: float,
        preview_y_pt: float,
        scale_x: float,
        scale_y: float,
        image_cache: dict[str, dict[str, Any]],
    ) -> None:
        asset = ProductionExportService._load_image_asset(layer.get("image_url"), image_cache)
        if not asset:
            return

        box_width_pt = float(layer.get("box_size_px", 0.0) or 0.0) * scale_x
        box_height_pt = float(layer.get("box_size_px", 0.0) or 0.0) * scale_y
        left_pt = preview_x_pt + float(layer.get("left_px", 0.0) or 0.0) * scale_x
        top_px = float(layer.get("top_px", 0.0) or 0.0)
        canvas_height_px = float(layer.get("canvas_height_px", 0.0) or 0.0)
        box_size_px = float(layer.get("box_size_px", 0.0) or 0.0)
        bottom_pt = preview_y_pt + (canvas_height_px - top_px - box_size_px) * scale_y

        crop_offset_x_pt = float(layer.get("visible_offset_x_px", 0.0) or 0.0) * scale_x
        crop_offset_y_pt = float(layer.get("visible_offset_y_px", 0.0) or 0.0) * scale_y
        visible_width_pt = float(layer.get("visible_width_px", 0.0) or 0.0) * scale_x
        visible_height_pt = float(layer.get("visible_height_px", 0.0) or 0.0) * scale_y
        rotation_degrees = float(layer.get("rotation_degrees", 0.0) or 0.0)

        pdf.saveState()
        center_x = left_pt + (box_width_pt / 2)
        center_y = bottom_pt + (box_height_pt / 2)
        pdf.translate(center_x, center_y)
        pdf.rotate(rotation_degrees)

        clip_x = (-box_width_pt / 2) + crop_offset_x_pt
        clip_y = (box_height_pt / 2) - crop_offset_y_pt - visible_height_pt
        clip_path = pdf.beginPath()
        clip_path.rect(clip_x, clip_y, visible_width_pt, visible_height_pt)
        pdf.clipPath(clip_path, stroke=0, fill=0)

        pdf.drawImage(
            asset["reader"],
            -box_width_pt / 2,
            -box_height_pt / 2,
            width=box_width_pt,
            height=box_height_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
        pdf.restoreState()

    @staticmethod
    def _render_pdf(payload: dict[str, Any], dpi: int = 300) -> bytes:
        buffer = BytesIO()
        pdf = canvas.Canvas(buffer, pagesize=A4)
        image_cache: dict[str, dict[str, Any]] = {}
        ProductionExportService._ensure_pdf_fonts()

        items = payload.get("items") or []
        for item_index, item in enumerate(items):
            views = ProductionExportService._sorted_views(item)
            for view_index, view in enumerate(views):
                ProductionExportService._draw_pdf_preview_page(
                    pdf=pdf,
                    payload=payload,
                    item=item,
                    item_index=item_index,
                    view=view,
                    view_index=view_index,
                    view_count=len(views),
                    image_cache=image_cache,
                    dpi=dpi,
                )
                pdf.showPage()
            ProductionExportService._draw_pdf_sticker_sheet(
                pdf=pdf,
                payload=payload,
                item=item,
                image_cache=image_cache,
                dpi=dpi,
            )
            if item_index < len(items) - 1:
                pdf.showPage()

        pdf.save()
        return buffer.getvalue()

    @staticmethod
    def _draw_pdf_preview_page(
        pdf: canvas.Canvas,
        payload: dict[str, Any],
        item: dict[str, Any],
        item_index: int,
        view: dict[str, Any],
        view_index: int,
        view_count: int,
        image_cache: dict[str, dict[str, Any]],
        dpi: int,
    ) -> None:
        margin_x = 14 * mm
        top_y = ProductionExportService.PAGE_HEIGHT_PT - (18 * mm)

        pdf.setTitle(f"Đơn hàng {payload.get('order_id')} - Chế độ xem sản xuất")
        ProductionExportService._set_pdf_font(pdf, 16, bold=True)
        pdf.drawString(margin_x, top_y, f"Đơn hàng #{payload.get('order_id')} - Chế độ xem sản xuất")

        ProductionExportService._set_pdf_font(pdf, 10)
        pdf.setFillColor(colors.HexColor("#374151"))
        meta_lines = [
            f"Mục {item_index + 1}: {item.get('product_name') or 'Thiết kế nón bảo hiểm'}",
            f"Góc hiển thị: {ProductionExportService._view_label(view)} ({view_index + 1}/{view_count})",
            f"Trạng thái đơn: {ProductionExportService._order_status_label(payload.get('status'))}",
            f"Trạng thái thanh toán: {ProductionExportService._payment_status_label(payload.get('payment_status'))}",
            f"Hỗ trợ hoàn tiền: {ProductionExportService._refund_support_label(payload.get('refund_support_status'))}",
            f"Số lượng: {item.get('quantity')}",
            f"DPI mục tiêu: {dpi}",
        ]
        if payload.get("rejection_reason"):
            meta_lines.append(f"Lý do từ chối: {payload.get('rejection_reason')}")

        current_y = top_y - (8 * mm)
        for line in meta_lines:
            pdf.drawString(margin_x, current_y, line)
            current_y -= 5 * mm

        preview_width_pt = 120 * mm
        preview_height_pt = 112 * mm
        preview_x_pt = margin_x
        preview_y_pt = current_y - preview_height_pt - (4 * mm)

        pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
        pdf.setFillColor(colors.HexColor("#FFFFFF"))
        pdf.rect(preview_x_pt, preview_y_pt, preview_width_pt, preview_height_pt, stroke=1, fill=1)

        base_asset = ProductionExportService._load_image_asset(
            ProductionExportService._resolve_view_base_image(item, view),
            image_cache,
        )
        ProductionExportService._draw_image_contain(
            pdf,
            base_asset,
            preview_x_pt,
            preview_y_pt,
            preview_width_pt,
            preview_height_pt,
        )

        scale_x = preview_width_pt / float(item.get("canvas_width_px", 1.0) or 1.0)
        scale_y = preview_height_pt / float(item.get("canvas_height_px", 1.0) or 1.0)
        for layer in view.get("layers") or []:
            ProductionExportService._draw_layer_preview(
                pdf=pdf,
                layer=layer,
                preview_x_pt=preview_x_pt,
                preview_y_pt=preview_y_pt,
                scale_x=scale_x,
                scale_y=scale_y,
                image_cache=image_cache,
            )

        info_x = preview_x_pt + preview_width_pt + (10 * mm)
        info_y = preview_y_pt + preview_height_pt
        pdf.setFillColor(colors.HexColor("#111827"))
        ProductionExportService._set_pdf_font(pdf, 11, bold=True)
        pdf.drawString(
            info_x,
            info_y,
            f"Thông số sticker - {ProductionExportService._view_label(view)}",
        )
        info_y -= 6 * mm

        ProductionExportService._set_pdf_font(pdf, 9)
        for layer in view.get("layers") or []:
            lines = [
                f"- {layer.get('sticker_name') or 'Sticker'}",
                f"  Kích thước: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                f"  Vị trí: {ProductionExportService._position_label(layer.get('position_label'))} | x={layer.get('x'):.3f}, y={layer.get('y'):.3f}",
                f"  Góc xoay: {layer.get('rotation_degrees')}° | z={layer.get('z_index')}",
            ]
            for line in lines:
                pdf.drawString(info_x, info_y, line)
                info_y -= 4.5 * mm
            info_y -= 1.5 * mm
            if info_y <= 18 * mm:
                break

        if not (view.get("layers") or []):
            pdf.drawString(info_x, info_y, "Không có sticker ở góc này.")

        ProductionExportService._set_pdf_font(pdf, 8, italic=True)
        pdf.setFillColor(colors.HexColor("#6B7280"))
        pdf.drawString(
            margin_x,
            12 * mm,
            "Bản xem trước dùng đúng snapshot x/y/scale/rotation được lưu tại thời điểm đặt hàng.",
        )

    @staticmethod
    def _draw_pdf_sticker_sheet(
        pdf: canvas.Canvas,
        payload: dict[str, Any],
        item: dict[str, Any],
        image_cache: dict[str, dict[str, Any]],
        dpi: int,
    ) -> None:
        margin_x = 14 * mm
        margin_top = ProductionExportService.PAGE_HEIGHT_PT - (16 * mm)
        current_y = margin_top

        def start_page_header() -> float:
            ProductionExportService._set_pdf_font(pdf, 15, bold=True)
            pdf.setFillColor(colors.HexColor("#111827"))
            pdf.drawString(margin_x, ProductionExportService.PAGE_HEIGHT_PT - (18 * mm), "Phiếu in sticker")
            ProductionExportService._set_pdf_font(pdf, 10)
            pdf.setFillColor(colors.HexColor("#374151"))
            pdf.drawString(
                margin_x,
                ProductionExportService.PAGE_HEIGHT_PT - (24 * mm),
                f"Đơn #{payload.get('order_id')} | Sản phẩm: {item.get('product_name') or 'Thiết kế nón bảo hiểm'} | DPI mục tiêu: {dpi}",
            )
            return ProductionExportService.PAGE_HEIGHT_PT - (32 * mm)

        current_y = start_page_header()
        for copy_index in range(int(item.get("quantity", 0) or 0)):
            ProductionExportService._set_pdf_font(pdf, 10, bold=True)
            pdf.setFillColor(colors.HexColor("#111827"))
            pdf.drawString(margin_x, current_y, f"Bộ bản in {copy_index + 1}/{item.get('quantity')}")
            current_y -= 6 * mm

            for view in ProductionExportService._sorted_views(item):
                view_layers = list(view.get("layers") or [])
                if not view_layers:
                    continue

                if current_y - (8 * mm) <= 16 * mm:
                    pdf.showPage()
                    current_y = start_page_header()

                ProductionExportService._set_pdf_font(pdf, 9, bold=True)
                pdf.setFillColor(colors.HexColor("#111827"))
                pdf.drawString(
                    margin_x,
                    current_y,
                    f"Góc: {ProductionExportService._view_label(view)}",
                )
                current_y -= 5.5 * mm

                for layer in view_layers:
                    draw_width_pt = float(layer.get("render_width_mm", 0.0) or 0.0) * mm
                    draw_height_pt = float(layer.get("render_height_mm", 0.0) or 0.0) * mm
                    box_size_pt = float(layer.get("box_size_mm", 0.0) or 0.0) * mm
                    row_height_pt = max(draw_height_pt, 20 * mm) + (10 * mm)

                    if current_y - row_height_pt <= 16 * mm:
                        pdf.showPage()
                        current_y = start_page_header()
                        ProductionExportService._set_pdf_font(pdf, 9, bold=True)
                        pdf.setFillColor(colors.HexColor("#111827"))
                        pdf.drawString(
                            margin_x,
                            current_y,
                            f"Góc: {ProductionExportService._view_label(view)}",
                        )
                        current_y -= 5.5 * mm

                    image_x = margin_x + (4 * mm)
                    image_y = current_y - draw_height_pt - (2 * mm)
                    ProductionExportService._draw_pdf_printable_layer(
                        pdf=pdf,
                        layer=layer,
                        x_pt=image_x,
                        y_pt=image_y,
                        draw_width_pt=draw_width_pt,
                        draw_height_pt=draw_height_pt,
                        box_size_pt=box_size_pt,
                        image_cache=image_cache,
                    )

                    info_x = image_x + max(draw_width_pt, 32 * mm) + (10 * mm)
                    info_y = current_y - (1 * mm)
                    ProductionExportService._set_pdf_font(pdf, 9, bold=True)
                    pdf.setFillColor(colors.HexColor("#111827"))
                    pdf.drawString(info_x, info_y, layer.get("sticker_name") or "Sticker")
                    ProductionExportService._set_pdf_font(pdf, 8.5)
                    info_y -= 4.5 * mm
                    for line in [
                        f"Mã sticker: {layer.get('sticker_id') or '-'}",
                        f"Kích thước thực: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                        f"Vị trí dán: {ProductionExportService._position_label(layer.get('position_label'))}",
                        f"Góc xoay trên nón: {layer.get('rotation_degrees')}°",
                    ]:
                        pdf.drawString(info_x, info_y, line)
                        info_y -= 4.2 * mm

                    current_y -= row_height_pt

            current_y -= 2 * mm

    @staticmethod
    def _draw_pdf_printable_layer(
        pdf: canvas.Canvas,
        layer: dict[str, Any],
        x_pt: float,
        y_pt: float,
        draw_width_pt: float,
        draw_height_pt: float,
        box_size_pt: float,
        image_cache: dict[str, dict[str, Any]],
    ) -> None:
        pdf.saveState()
        pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
        pdf.setDash(3, 2)
        pdf.rect(x_pt, y_pt, draw_width_pt, draw_height_pt, stroke=1, fill=0)
        pdf.setDash()
        pdf.restoreState()

        asset = ProductionExportService._load_image_asset(layer.get("image_url"), image_cache)
        if not asset:
            ProductionExportService._set_pdf_font(pdf, 8)
            pdf.setFillColor(colors.HexColor("#6B7280"))
            pdf.drawString(x_pt + 4, y_pt + draw_height_pt - 10, "Không tải được ảnh")
            return

        crop = layer.get("crop") or {}
        crop_left = float(crop.get("left", 0.0) or 0.0)
        crop_bottom = float(crop.get("bottom", 1.0) or 1.0)

        full_x = x_pt - (crop_left * box_size_pt)
        full_y = y_pt - ((1.0 - crop_bottom) * box_size_pt)

        pdf.saveState()
        clip_path = pdf.beginPath()
        clip_path.rect(x_pt, y_pt, draw_width_pt, draw_height_pt)
        pdf.clipPath(clip_path, stroke=0, fill=0)
        pdf.drawImage(
            asset["reader"],
            full_x,
            full_y,
            width=box_size_pt,
            height=box_size_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
        pdf.restoreState()

    @staticmethod
    def _render_svg(payload: dict[str, Any]) -> str:
        image_cache: dict[str, dict[str, Any]] = {}
        defs: list[str] = []
        body: list[str] = []
        width_mm = ProductionExportService.PAGE_WIDTH_MM
        margin_mm = 14.0
        current_y_mm = 16.0
        clip_counter = 0

        body.append(
            f'<text x="{margin_mm}" y="{current_y_mm}" font-size="6" font-weight="700" fill="#111827">'
            f'Đơn hàng #{payload.get("order_id")} - Phiếu in sticker'
            "</text>"
        )
        current_y_mm += 8.0

        for item in payload.get("items") or []:
            item_title = html.escape(item.get("product_name") or "Thiết kế nón bảo hiểm")
            body.append(
                f'<text x="{margin_mm}" y="{current_y_mm}" font-size="4.5" font-weight="700" fill="#111827">'
                f"{item_title} - số lượng {item.get('quantity')}"
                "</text>"
            )
            current_y_mm += 6.0

            for copy_index in range(int(item.get("quantity", 0) or 0)):
                body.append(
                    f'<text x="{margin_mm}" y="{current_y_mm}" font-size="4" fill="#374151">'
                    f"Bộ bản in {copy_index + 1}/{item.get('quantity')}"
                    "</text>"
                )
                current_y_mm += 5.0

                for view in ProductionExportService._sorted_views(item):
                    view_layers = list(view.get("layers") or [])
                    if not view_layers:
                        continue

                    body.append(
                        f'<text x="{margin_mm}" y="{current_y_mm}" font-size="4" font-weight="700" fill="#111827">'
                        f"Góc: {html.escape(ProductionExportService._view_label(view))}"
                        "</text>"
                    )
                    current_y_mm += 5.0

                    for layer in view_layers:
                        draw_width_mm = float(layer.get("render_width_mm", 0.0) or 0.0)
                        draw_height_mm = float(layer.get("render_height_mm", 0.0) or 0.0)
                        box_size_mm = float(layer.get("box_size_mm", 0.0) or 0.0)
                        image_x_mm = margin_mm + 4.0
                        image_y_mm = current_y_mm
                        info_x_mm = image_x_mm + max(draw_width_mm, 32.0) + 8.0

                        body.append(
                            f'<rect x="{image_x_mm}" y="{image_y_mm}" width="{draw_width_mm}" height="{draw_height_mm}" '
                            'fill="none" stroke="#D1D5DB" stroke-dasharray="2 1.5" />'
                        )

                        image_tag = ProductionExportService._build_svg_image_tag(
                            layer=layer,
                            x_mm=image_x_mm,
                            y_mm=image_y_mm,
                            draw_width_mm=draw_width_mm,
                            draw_height_mm=draw_height_mm,
                            box_size_mm=box_size_mm,
                            clip_id=f"clip-{clip_counter}",
                            defs=defs,
                            image_cache=image_cache,
                        )
                        clip_counter += 1
                        if image_tag:
                            body.append(image_tag)

                        name = html.escape(layer.get("sticker_name") or "Sticker")
                        lines = [
                            name,
                            f"Mã sticker: {layer.get('sticker_id') or '-'}",
                            f"Kích thước thực: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                            f"Vị trí dán: {html.escape(ProductionExportService._position_label(layer.get('position_label')))} | góc xoay {layer.get('rotation_degrees')}°",
                        ]
                        for idx, line in enumerate(lines):
                            weight = "700" if idx == 0 else "400"
                            body.append(
                                f'<text x="{info_x_mm}" y="{image_y_mm + 4.5 + (idx * 4.5)}" '
                                f'font-size="3.8" font-weight="{weight}" fill="#111827">{html.escape(line)}</text>'
                            )

                        current_y_mm += max(draw_height_mm, 20.0) + 8.0

                current_y_mm += 2.0

            current_y_mm += 3.0

        total_height_mm = max(current_y_mm + 12.0, ProductionExportService.PAGE_HEIGHT_MM)
        base_defs = (
            "<style><![CDATA["
            "text { font-family: 'Arial', 'DejaVu Sans', sans-serif; }"
            "]]></style>"
        )
        defs_markup = f"<defs>{base_defs}{''.join(defs)}</defs>"
        return (
            '<?xml version="1.0" encoding="UTF-8"?>'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width_mm}mm" height="{total_height_mm}mm" '
            f'viewBox="0 0 {width_mm} {total_height_mm}" xml:lang="vi">'
            f"{defs_markup}"
            '<rect x="0" y="0" width="100%" height="100%" fill="#FFFFFF" />'
            f"{''.join(body)}"
            "</svg>"
        )

    @staticmethod
    def _build_svg_image_tag(
        layer: dict[str, Any],
        x_mm: float,
        y_mm: float,
        draw_width_mm: float,
        draw_height_mm: float,
        box_size_mm: float,
        clip_id: str,
        defs: list[str],
        image_cache: dict[str, dict[str, Any]],
    ) -> Optional[str]:
        href = ProductionExportService._svg_href(layer.get("image_url"), image_cache)
        if not href:
            return None

        crop = layer.get("crop") or {}
        crop_left = float(crop.get("left", 0.0) or 0.0)
        crop_bottom = float(crop.get("bottom", 1.0) or 1.0)
        full_x = x_mm - (crop_left * box_size_mm)
        full_y = y_mm - ((1.0 - crop_bottom) * box_size_mm)

        defs.append(
            f'<clipPath id="{clip_id}"><rect x="{x_mm}" y="{y_mm}" width="{draw_width_mm}" height="{draw_height_mm}" /></clipPath>'
        )
        return (
            f'<image href="{href}" x="{full_x}" y="{full_y}" width="{box_size_mm}" height="{box_size_mm}" '
            f'preserveAspectRatio="xMidYMid meet" clip-path="url(#{clip_id})" />'
        )

    @staticmethod
    def _svg_href(
        source: Optional[str],
        image_cache: dict[str, dict[str, Any]],
    ) -> Optional[str]:
        asset = ProductionExportService._load_image_asset(source, image_cache)
        if not asset:
            return None

        encoded = base64.b64encode(asset["bytes"]).decode("ascii")
        return f"data:{asset['mime_type']};base64,{encoded}"
