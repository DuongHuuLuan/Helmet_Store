import re
import unicodedata
from typing import Any, Dict, List, Optional

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import Product, Category
from app.services.product_service import ProductService
from app.services.warehouse_service import WarehouseService


class ChatbotCatalogService:
    _STOPWORDS = {
        "a",
        "an",
        "and",
        "ao",
        "ban",
        "bao",
        "bên",
        "cho",
        "co",
        "con",
        "cua",
        "cần",
        "duoc",
        "gia",
        "giá",
        "giup",
        "giúp",
        "hang",
        "hãy",
        "hay",
        "hien",
        "hiện",
        "khong",
        "không",
        "loai",
        "loại",
        "mai",
        "minh",
        "mình",
        "mu",
        "mũ",
        "muon",
        "muốn",
        "nao",
        "nào",
        "nay",
        "này",
        "nen",
        "nên",
        "non",
        "nón",
        "san",
        "shop",
        "sp",
        "toi",
        "tôi",
        "tu",
        "tư",
        "van",
        "ve",
        "về",
        "voi",
        "với",
    }

    _CATEGORY_ALIASES = {
        "Mu bao hiem 1/2": ("non 1/2", "mu 1/2", "1/2", "non nua dau", "nua dau"),
        "Mu FULLFACE": ("fullface", "full face", "non fullface"),
        "Mu bao hiem 3/4": ("3/4", "non 3/4", "mu 3/4"),
        "Mu tre em": ("non tre em", "mu tre em", "tre em"),
        "Mu lat ham": ("lat ham", "ham", "non lat ham"),
        "Mu xe dap": ("non xe dap", "mu xe dap", "xe dap"),
    }


    @staticmethod
    def _normalize_text(value: Optional[str]) -> str:
        raw = (value or "").strip().lower().replace("đ", "d")
        normalized = unicodedata.normalize("NFD", raw)
        return "".join(ch for ch in normalized if unicodedata.category(ch) != "Mn")

    @staticmethod
    def _tokenize_query(query: str) -> List[str]:
        normalized = ChatbotCatalogService._normalize_text(query)
        tokens = re.findall(r"[a-z0-9/]+", normalized)
        return [
            token
            for token in tokens
            if len(token) >= 2 and token not in ChatbotCatalogService._STOPWORDS
        ]

    @staticmethod
    def _parse_budget_cap(query: str) -> Optional[int]:
        normalized = ChatbotCatalogService._normalize_text(query)
        patterns = [
            (r"(?:duoi|toi da|khong qua|<=|<)\s*(\d+(?:[.,]\d+)?)\s*(trieu|m)\b", 1_000_000),
            (r"(?:duoi|toi da|khong qua|<=|<)\s*(\d+(?:[.,]\d+)?)\s*(k|nghin|ngan)\b", 1_000),
            (r"(?:duoi|toi da|khong qua|<=|<)\s*(\d{5,9})\b", 1),
            (r"(\d+(?:[.,]\d+)?)\s*(trieu|m)\b", 1_000_000),
            (r"(\d+(?:[.,]\d+)?)\s*(k|nghin|ngan)\b", 1_000),
        ]
        for pattern, multiplier in patterns:
            match = re.search(pattern, normalized)
            if not match:
                continue
            try:
                amount = float(match.group(1).replace(",", "."))
            except ValueError:
                continue
            return int(amount * multiplier)
        return None
    

    # hàm lấy cả sticker còn hạn dựa trên tên sản phẩm
    @staticmethod
    def resolve_categories_from_query(db: Session, query: str) -> List[Category]:
        normalized_query = ChatbotCatalogService._normalize_text(query)
        if not normalized_query:
            return []

        categories = db.query(Category).order_by(Category.id.asc()).all()
        matched_by_id: Dict[int, Category] = {}

        for category in categories:
            normalized_name = ChatbotCatalogService._normalize_text(
                getattr(category, "name", "")
            )
            if normalized_name and normalized_name in normalized_query:
                matched_by_id[category.id] = category
                continue

            for aliases in ChatbotCatalogService._CATEGORY_ALIASES.values():
                if any(alias in normalized_query for alias in aliases):
                    if any(alias in normalized_name for alias in aliases):
                        matched_by_id[category.id] = category
                        break

        if matched_by_id:
            return list(matched_by_id.values())

        candidate_products = ChatbotCatalogService.search_products(
            db=db,
            query=query,
            limit=settings.CHATBOT_MAX_PRODUCTS,
        )
        candidate_category_ids = {
            item["category_id"]
            for item in candidate_products
            if isinstance(item.get("category_id"), int)
        }
        return [category for category in categories if category.id in candidate_category_ids]


    @staticmethod
    def _pick_image_url(product: Product, color_id: Optional[int] = None) -> Optional[str]:
        images = list(getattr(product, "product_images", []) or [])
        if color_id is not None:
            for image in images:
                if getattr(image, "color_id", None) == color_id and not getattr(image, "view_image_key", None):
                    return getattr(image, "url", None)
        for image in images:
            if not getattr(image, "view_image_key", None):
                return getattr(image, "url", None)
        if images:
            return getattr(images[0], "url", None)
        return None

    @staticmethod
    def _truncate_description(description: Optional[str], max_length: int = 140) -> Optional[str]:
        text = (description or "").strip()
        if not text:
            return None
        if len(text) <= max_length:
            return text
        return text[: max_length - 1].rstrip() + "…"

    @staticmethod
    def _build_variants(db: Session, product: Product, price_cap: Optional[int]) -> List[Dict[str, Any]]:
        variants: List[Dict[str, Any]] = []
        for detail in getattr(product, "product_details", []) or []:
            if not getattr(detail, "is_active", False):
                continue
            price = getattr(detail, "price", None)
            if price_cap is not None and isinstance(price, int) and price > price_cap:
                continue

            stock = WarehouseService.get_total_stock(db, detail)
            variants.append(
                {
                    "product_detail_id": detail.id,
                    "color_id": getattr(detail, "color_id", None),
                    "color_name": getattr(getattr(detail, "color", None), "name", None),
                    "size_id": getattr(detail, "size_id", None),
                    "size_name": getattr(getattr(detail, "size", None), "size", None),
                    "stock": stock,
                    "is_available": stock > 0,
                    "price": price,
                }
            )

        variants.sort(
            key=lambda item: (
                not item["is_available"],
                -(item["stock"] or 0),
                item["price"] if isinstance(item["price"], int) else 10**12,
                item["product_detail_id"],
            )
        )
        return variants

    @staticmethod
    def _calculate_product_score(product: Product, query_tokens: List[str], budget_cap: Optional[int]) -> int:
        variant_terms = []
        for detail in getattr(product, "product_details", []) or []:
            color_name = getattr(getattr(detail, "color", None), "name", None)
            size_name = getattr(getattr(detail, "size", None), "size", None)
            if color_name:
                variant_terms.append(color_name)
            if size_name:
                variant_terms.append(size_name)

        searchable_text = " ".join(
            [
                getattr(product, "name", "") or "",
                getattr(getattr(product, "category", None), "name", "") or "",
                getattr(product, "description", "") or "",
                " ".join(variant_terms),
            ]
        )
        normalized_text = ChatbotCatalogService._normalize_text(searchable_text)
        score = 0

        for token in query_tokens:
            if token in ChatbotCatalogService._normalize_text(getattr(product, "name", "")):
                score += 5
            elif token in ChatbotCatalogService._normalize_text(
                getattr(getattr(product, "category", None), "name", "")
            ):
                score += 4
            elif token in normalized_text:
                score += 2

        if budget_cap is not None:
            prices = [
                getattr(detail, "price", None)
                for detail in getattr(product, "product_details", []) or []
                if getattr(detail, "is_active", False) and isinstance(getattr(detail, "price", None), int)
            ]
            if prices and min(prices) <= budget_cap:
                score += 1

        return score

    @staticmethod
    def _build_actions(product_id: int, variants: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        actions: List[Dict[str, Any]] = [
            {
                "type": "view_detail",
                "label": "Xem chi tiết",
                "target": f"/products/{product_id}",
            }
        ]
        available_variants = [item for item in variants if item["is_available"]]
        if len(available_variants) == 1:
            actions.append(
                {
                    "type": "add_to_cart",
                    "label": "Thêm vào giỏ",
                    "product_detail_id": available_variants[0]["product_detail_id"],
                }
            )
        return actions

    @staticmethod
    def search_products(
        db: Session,
        query: str,
        limit: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        max_products = max(1, limit or settings.CHATBOT_MAX_PRODUCTS)
        base_page = ProductService.get_products_paginated(
            db=db,
            page=1,
            per_page=None,
            keyword=None,
            category_id=None,
        )
        products = base_page.get("items") or []

        query_tokens = ChatbotCatalogService._tokenize_query(query)
        budget_cap = ChatbotCatalogService._parse_budget_cap(query)
        if not query_tokens and budget_cap is None:
            return []

        product_cards: List[Dict[str, Any]] = []

        for product in products:
            score = ChatbotCatalogService._calculate_product_score(
                product=product,
                query_tokens=query_tokens,
                budget_cap=budget_cap,
            )
            if query_tokens and score <= 0:
                continue

            variants = ChatbotCatalogService._build_variants(
                db=db,
                product=product,
                price_cap=budget_cap,
            )
            if not variants:
                continue

            selected_variants = variants[:3]
            available_variants = [item for item in variants if item["is_available"]]
            primary_variant = available_variants[0] if available_variants else selected_variants[0]
            product_cards.append(
                {
                    "score": score,
                    "product_id": product.id,
                    "category_id": getattr(product, "category_id", None),
                    "name": getattr(product, "name", "") or "",
                    "image_url": ChatbotCatalogService._pick_image_url(
                        product,
                        color_id=primary_variant.get("color_id"),
                    ),
                    "price": primary_variant.get("price"),
                    "short_description": ChatbotCatalogService._truncate_description(
                        getattr(product, "description", None)
                    ),
                    "category_name": getattr(getattr(product, "category", None), "name", None),
                    "variants": [
                        {
                            "product_detail_id": item["product_detail_id"],
                            "color_id": item["color_id"],
                            "color_name": item["color_name"],
                            "size_id": item["size_id"],
                            "size_name": item["size_name"],
                            "stock": item["stock"],
                            "is_available": item["is_available"],
                        }
                        for item in selected_variants
                    ],
                    "actions": ChatbotCatalogService._build_actions(
                        product_id=product.id,
                        variants=variants,
                    ),
                    "llm_candidate": {
                        "product_id": product.id,
                        "name": getattr(product, "name", "") or "",
                        "category_name": getattr(getattr(product, "category", None), "name", None),
                        "price": primary_variant.get("price"),
                        "available_variant_count": len(available_variants),
                        "summary": ChatbotCatalogService._truncate_description(
                            getattr(product, "description", None),
                            max_length=100,
                        ),
                    },
                }
            )

        product_cards.sort(
            key=lambda item: (
                -item["score"],
                item["price"] if isinstance(item["price"], int) else 10**12,
                -item["product_id"],
            )
        )
        return product_cards[:max_products]
