from typing import List, Optional

from app.domain.repositories.evaluate_repository import EvaluateRepository


class GetProductEvaluationsUseCase:
    def __init__(self, evaluate_repository: EvaluateRepository):
        self._repo = evaluate_repository

    def execute(self, product_id: int,
                page: int = 1, per_page: int = 3) -> dict:
        data = self._repo.get_product_evaluations_data(
            product_id=product_id,
            page=page,
            per_page=per_page,
        )

        total = data["total"]
        avg_rate = data["avg_rate"]
        rate_count_map = data["rate_count_map"]
        total_with_images = data["total_with_images"]
        sample_contents = data["sample_contents"]
        evaluate_ids = data["evaluate_ids"]
        evaluates_raw = data["evaluates_raw"]
        total_pages = data["total_pages"]

        items = []
        for ev in evaluates_raw:
            evaluater_name = ev.get("username")
            items.append({
                "id": ev["id"],
                "order_id": ev["order_id"],
                "user_id": ev["user_id"],
                "admin_id": ev["admin_id"],
                "rate": ev["rate"],
                "content": ev["content"],
                "admin_reply": ev["admin_reply"],
                "admin_replied_at": ev["admin_replied_at"],
                "created_at": ev["created_at"],
                "updated_at": ev["updated_at"],
                "images": ev.get("images", []),
                "evaluater_name": evaluater_name,
                "evaluater_name_masked": self._mask_username(evaluater_name),
                "matched_variants": self._matched_variants_for_product(ev, product_id),
                "has_images": bool(ev.get("images")),
            })

        return {
            "summary": {
                "product_id": product_id,
                "average_rate": round(float(avg_rate or 0), 1),
                "total_evaluates": total,
                "total_with_images": total_with_images,
                "summary_text": self._build_product_summary_text(
                    total_evaluates=total,
                    average_rate=float(avg_rate or 0),
                    rate_count_map=rate_count_map,
                    sample_contents=sample_contents,
                ),
                "rate_counts": [
                    {"star": star, "count": int(rate_count_map.get(star, 0))}
                    for star in range(5, 0, -1)
                ],
            },
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }

    def _mask_username(self, username: Optional[str]) -> Optional[str]:
        name = (username or "").strip()
        if not name:
            return None
        if len(name) <= 2:
            return f"{name[0]}*" if len(name) == 2 else "*"
        return f"{name[:1]}{'*' * max(3, len(name) - 2)}{name[-1:]}"

    def _matched_variants_for_product(self, ev: dict, product_id: int) -> List[str]:
        order = ev.get("order")
        if not order:
            return []

        variants: List[str] = []
        for od in order.get("order_details", []):
            pd = od.get("product_detail")
            if not pd or pd.get("product_id") != product_id:
                continue

            color = pd.get("color") or {}
            size = pd.get("size") or {}
            parts = []
            if color.get("name"):
                parts.append(f"Màu: {color['name']}")
            if size.get("size"):
                parts.append(f"Kích thước: {size['size']}")
            label = ", ".join(parts) if parts else f"Biến thể #{pd.get('id')}"
            if label not in variants:
                variants.append(label)

        return variants

    def _build_product_summary_text(
        self,
        total_evaluates: int,
        average_rate: float,
        rate_count_map: dict,
        sample_contents: List[str],
    ) -> Optional[str]:
        if total_evaluates <= 0:
            return None

        top_star = None
        top_count = -1
        for star in range(5, 0, -1):
            count = int(rate_count_map.get(star, 0))
            if count > top_count:
                top_star = star
                top_count = count

        parts = [
            f"Có {total_evaluates} đánh giá, trung bình {average_rate:.1f}/5 sao."
        ]
        if top_star and top_count > 0:
            parts.append(f"Mức {top_star} sao xuất hiện nhiều nhất ({top_count} đánh giá).")
        if sample_contents:
            snippet = sample_contents[0].strip().replace("\n", " ")
            if len(snippet) > 160:
                snippet = f"{snippet[:157].rstrip()}..."
            parts.append(f"Nhận xét nổi bật: {snippet}")
        return " ".join(parts)
