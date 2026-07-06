import re
from decimal import Decimal
from typing import Any, Dict, List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.infrastructure.database.models import Conversation, Message
from app.infrastructure.database.models.conversation import ConversationStatus
from app.infrastructure.database.models.message import MessageType
from app.infrastructure.database.models.order import OrderStatus, PaymentStatus, RefundSupportStatus
from app.application.chat.chat_service import ChatService
from app.domain.repositories.message_repository import MessageRepository
from app.infrastructure.repositories.cart_repository_impl import CartRepositoryImpl
from app.infrastructure.repositories.message_repository_impl import MessageRepositoryImpl
from app.application.chat.catalog_service import ChatbotCatalogService
from app.infrastructure.repositories.discount_repository_impl import DiscountRepositoryImpl
from app.infrastructure.external.openai.chat_service import OpenAIChatService
from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl


class ChatbotService:
    _HANDOFF_KEYWORDS = (
        "bao hanh",
        "khieu nai",
        "hoan tien",
        "refund",
        "thanh toan loi",
        "gap nhan vien",
        "gap admin",
        "lien he nguoi ban",
        "lien he shop",
        "tu van vien",
        "cua ai",
        "do ai lam"
        "du an nay cua ai" 
    )
    _ORDER_LOOKUP_KEYWORDS = (
        "don hang",
        "ma don",
        "kiem tra don",
        "tra cuu don",
        "order",
        "giao den dau",
        "giao toi dau",
        "da giao chua",
        "trang thai don",
    )
    _DISCOUNT_LOOKUP_KEYWORDS = (
        "ma giam gia",
        "voucher",
        "coupon",
        "khuyen mai",
        "ma khuyen mai",
        "code giam",
        "code khuyen mai",
        "uu dai",
        "ma uu dai",
    )

    _RECENT_ORDER_KEYWORDS = (
        "don gan nhat",
        "don hang gan nhat",
        "order gan nhat",
        "don moi nhat",
        "order moi nhat",
        "cua dong hang gan nhat",
        "don hang moi nhat cua toi",
        "don hang gan day",
    )
    _ORDER_TOTAL_KEYWORDS = (
        "gia bao nhieu",
        "tong bao nhieu",
        "het bao nhieu",
        "bao nhieu tien",
    )
    _ORDER_APPLIED_DISCOUNT_KEYWORDS = (
        "khuyen mai nao ap dung",
        "ma giam gia nao ap dung",
        "voucher nao ap dung",
        "ma nao ap dung",
        "ap dung ma nao",
        "don hang moi nhat"
    )


    _GENERIC_DISCOUNT_CODE_TOKENS = {
        "code",
        "coupon",
        "discount",
        "giam",
        "giamgia",
        "khuyenmai",
        "ma",
        "nay",
        "nao",
        "uu",
        "uu dai",
        "voucher",
        "khuyen mai",
    }
    _ORDER_ID_PATTERN = re.compile(
        r"(?:#|ma\s*don|don|order)\s*#?\s*(\d{1,9})",
        re.IGNORECASE,
    )
    _DISCOUNT_CODE_PATTERN = re.compile(
        r"(?:ma|voucher|coupon|code)\s*(?:giam\s*gia|khuyen\s*mai|uu\s*dai)?\s*[:#-]?\s*([a-z0-9_-]{3,40})",
        re.IGNORECASE,
    )
    _ORDER_STATUS_LABELS = {
        OrderStatus.PENDING.value: "Đang chờ xử lý",
        OrderStatus.SHIPPING.value: "Đang giao hàng",
        OrderStatus.COMPLETED.value: "Đã giao thành công",
        OrderStatus.CANCELLED.value: "Đã hủy",
    }
    _PAYMENT_STATUS_LABELS = {
        PaymentStatus.UNPAID.value: "Chưa thanh toán",
        PaymentStatus.PAID.value: "Đã thanh toán",
    }
    _REFUND_STATUS_LABELS = {
        RefundSupportStatus.NONE.value: "Không có yêu cầu hỗ trợ thêm",
        RefundSupportStatus.CONTACT_REQUIRED.value: "Cần tư vấn viên hỗ trợ thêm",
        RefundSupportStatus.RESOLVED.value: "Đã được hỗ trợ",
    }

    @staticmethod
    def _normalize_text(value: Optional[str]) -> str:
        return ChatbotCatalogService._normalize_text(value)

    @staticmethod
    def _should_handoff(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._HANDOFF_KEYWORDS)

    @staticmethod
    def _should_lookup_order(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._ORDER_LOOKUP_KEYWORDS)

    @staticmethod
    def _should_lookup_discount(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return any(keyword in normalized_text for keyword in ChatbotService._DISCOUNT_LOOKUP_KEYWORDS)

    @staticmethod
    def _extract_order_id(message_text: str) -> Optional[int]:
        normalized_text = ChatbotService._normalize_text(message_text)
        match = ChatbotService._ORDER_ID_PATTERN.search(normalized_text)
        if not match:
            return None
        try:
            return int(match.group(1))
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _extract_discount_code(message_text: str) -> Optional[str]:
        normalized_text = ChatbotService._normalize_text(message_text)
        match = ChatbotService._DISCOUNT_CODE_PATTERN.search(normalized_text)
        if not match:
            return None

        code = (match.group(1) or "").strip().lower()
        if not code or code in ChatbotService._GENERIC_DISCOUNT_CODE_TOKENS:
            return None
        return code
    
    @staticmethod
    def _contains_any(normalized_text: str, keywords: tuple[str, ...]) -> bool:
        return any(keyword in normalized_text for keyword in keywords)

    @staticmethod
    def _is_recent_order_total_query(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)
        return (
            ChatbotService._contains_any(normalized_text, ChatbotService._RECENT_ORDER_KEYWORDS)
            and ChatbotService._contains_any(normalized_text, ChatbotService._ORDER_TOTAL_KEYWORDS)
        )

    @staticmethod
    def _is_recent_order_discount_query(message_text: str) -> bool:
        normalized_text = ChatbotService._normalize_text(message_text)

        has_recent_order = ChatbotService._contains_any(
            normalized_text,
            ChatbotService._RECENT_ORDER_KEYWORDS,
        )
        has_discount_noun = ChatbotService._contains_any(
            normalized_text,
            (
                "khuyen mai",
                "ma giam gia",
                "voucher",
                "coupon",
                "ma khuyen mai",
                "uu dai",
            ),
        )
        has_apply_word = (
            "ap dung" in normalized_text
            or "dang duoc ap dung" in normalized_text
            or "da ap dung" in normalized_text
        )

        return has_recent_order and has_discount_noun and has_apply_word


    @staticmethod
    def _format_discount_names(discounts: List[Any]) -> str:
        names = [
            str(getattr(item, "name", "") or "").upper()
            for item in discounts
            if str(getattr(item, "name", "") or "").strip()
        ]
        return ", ".join(names) if names else "không có mã nào"

    @staticmethod
    def _format_currency(value: Any) -> str:
        try:
            amount = Decimal(str(value or 0))
        except Exception:
            amount = Decimal("0")
        return f"{amount:,.0f}đ".replace(",", ".")

    @staticmethod
    def _is_enabled() -> bool:
        return bool(settings.CHATBOT_ENABLED)

    @staticmethod
    def _load_recent_messages(
        msg_repo: MessageRepository,
        conversation: Conversation,
        limit: int = 6,
    ) -> List[Dict[str, str]]:
        rows = msg_repo.get_recent_messages(
            conversation.id,
            limit,
            exclude_deleted=True,
        )
        rows.reverse()

        history: List[Dict[str, str]] = []
        for row in rows:
            serialized = ChatService.serialize_message(row)
            content = str(serialized.get("content") or "").strip()
            if not content:
                continue

            sender_role = serialized.get("sender_role")
            if not sender_role:
                sender_role = "user" if row.user_id == conversation.user_id else "admin"

            history.append(
                {
                    "sender_role": str(sender_role),
                    "content": content,
                }
            )
        return history

    @staticmethod
    def _find_existing_bot_reply(
        msg_repo: MessageRepository,
        conversation: Conversation,
        user_message_id: int,
    ) -> Optional[Message]:
        rows = msg_repo.find_existing_bot_reply(
            conversation.id,
            conversation.admin_id,
            user_message_id,
        )
        for row in rows:
            metadata = ChatService._parse_message_metadata(row)
            if metadata.get("sender_role") != "bot":
                continue
            if metadata.get("reply_to_message_id") == user_message_id:
                return row
        return None

    @staticmethod
    def _build_product_payload(
        selected_products: List[Dict[str, Any]],
        follow_up_suggestions: List[str],
    ) -> Dict[str, Any]:
        return {
            "kind": "product_list",
            "title": "Gợi ý cho bạn",
            "products": [
                {
                    "product_id": item["product_id"],
                    "name": item["name"],
                    "image_url": item["image_url"],
                    "price": item["price"],
                    "short_description": item["short_description"],
                    "category_name": item["category_name"],
                    "variants": item["variants"],
                    "actions": item["actions"],
                }
                for item in selected_products
            ],
            "follow_up_suggestions": follow_up_suggestions[:3],
        }

    @staticmethod
    def _pick_products_for_reply(
        candidate_products: List[Dict[str, Any]],
        matched_product_ids: List[int],
    ) -> List[Dict[str, Any]]:
        products_by_id = {int(item["product_id"]): item for item in candidate_products}
        selected_products: List[Dict[str, Any]] = []
        seen_ids: set[int] = set()

        for product_id in matched_product_ids:
            if product_id in seen_ids:
                continue
            candidate = products_by_id.get(product_id)
            if not candidate:
                continue
            seen_ids.add(product_id)
            selected_products.append(candidate)

        if selected_products:
            return selected_products[: settings.CHATBOT_MAX_PRODUCTS]

        return candidate_products[: settings.CHATBOT_MAX_PRODUCTS]

    @staticmethod
    def _resolve_shipping_fee(order: Any) -> Decimal:
        ghn_shipments = getattr(order, "ghn_shipments", None) or []
        if not ghn_shipments:
            return Decimal("0")
        ordered_shipments = sorted(
            list(ghn_shipments),
            key=lambda item: (
                getattr(item, "created_at", None),
                getattr(item, "id", 0),
            ),
            reverse=True,
        )
        raw_fee = getattr(ordered_shipments[0], "shipping_fee", None)
        return Decimal(str(raw_fee or 0))

    @staticmethod
    def _build_order_payload(order: Any) -> Dict[str, Any]:
        status_value = getattr(getattr(order, "status", None), "value", getattr(order, "status", "pending"))
        payment_status_value = getattr(
            getattr(order, "payment_status", None),
            "value",
            getattr(order, "payment_status", "unpaid"),
        )
        refund_status_value = getattr(
            getattr(order, "refund_support_status", None),
            "value",
            getattr(order, "refund_support_status", "none"),
        )
        shipping_fee = ChatbotService._resolve_shipping_fee(order)
        items: List[Dict[str, Any]] = []
        subtotal = Decimal("0")

        for detail in getattr(order, "order_details", []) or []:
            unit_price = Decimal(str(getattr(detail, "price", 0) or 0))
            quantity = int(getattr(detail, "quantity", 0) or 0)
            subtotal += unit_price * quantity
            product_detail = getattr(detail, "product_detail", None)
            product = getattr(product_detail, "product", None)
            product_images = list(getattr(product, "product_images", []) or [])
            image_url = getattr(product_images[0], "url", None) if product_images else None

            items.append(
                {
                    "product_name": getattr(product, "name", "Sản phẩm"),
                    "image_url": image_url,
                    "color_name": getattr(getattr(product_detail, "color", None), "name", None),
                    "size_name": getattr(getattr(product_detail, "size", None), "size", None),
                    "quantity": quantity,
                    "unit_price": float(unit_price),
                }
            )

        total_amount = subtotal + shipping_fee
        delivery_info = getattr(order, "delivery_info", None)
        payment_method = getattr(order, "payment_method", None)

        return {
            "kind": "order_summary",
            "title": f"Đơn hàng #{order.id}",
            "order": {
                "order_id": order.id,
                "status": status_value,
                "status_label": ChatbotService._ORDER_STATUS_LABELS.get(status_value, status_value),
                "payment_status": payment_status_value,
                "payment_status_label": ChatbotService._PAYMENT_STATUS_LABELS.get(
                    payment_status_value,
                    payment_status_value,
                ),
                "refund_support_status": refund_status_value,
                "refund_support_status_label": ChatbotService._REFUND_STATUS_LABELS.get(
                    refund_status_value,
                    refund_status_value,
                ),
                "created_at": (
                    getattr(order, "created_at", None).isoformat()
                    if getattr(order, "created_at", None) is not None
                    else None
                ),
                "shipping_fee": float(shipping_fee),
                "total_amount": float(total_amount),
                "total_items": sum(int(item["quantity"]) for item in items),
                "payment_method_name": getattr(payment_method, "name", None),
                "recipient_name": getattr(delivery_info, "name", None),
                "recipient_phone": getattr(delivery_info, "phone", None),
                "delivery_address": getattr(delivery_info, "address", None),
                "items": items[:3],
            },
        }

    @staticmethod
    def _build_order_message(order: Any, requested_order_id: Optional[int]) -> str:
        status_value = getattr(getattr(order, "status", None), "value", getattr(order, "status", "pending"))
        payment_status_value = getattr(
            getattr(order, "payment_status", None),
            "value",
            getattr(order, "payment_status", "unpaid"),
        )
        order_label = ChatbotService._ORDER_STATUS_LABELS.get(status_value, status_value)
        payment_label = ChatbotService._PAYMENT_STATUS_LABELS.get(payment_status_value, payment_status_value)
        prefix = (
            f"Mình đã kiểm tra đơn #{order.id} của bạn."
            if requested_order_id is not None
            else f"Đơn gần nhất của bạn là #{order.id}."
        )
        return f"{prefix} Trạng thái hiện tại: {order_label}. Thanh toán: {payment_label}."

    @staticmethod
    def _build_discount_payload(
        discounts: List[Any],
        title: str,
        actions: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        return {
            "kind": "discount_list",
            "title": title,
            "discounts": [
                {
                    "discount_id": item.id,
                    "name": getattr(item, "name", "") or "",
                    "description": getattr(item, "description", None),
                    "percent": float(getattr(item, "percent", 0) or 0),
                    "status": getattr(getattr(item, "status", None), "value", getattr(item, "status", "")),
                    "category_id": getattr(item, "category_id", None),
                    "category_name": getattr(getattr(item, "category", None), "name", None),
                    "start_at": (
                        getattr(item, "start_at", None).isoformat()
                        if getattr(item, "start_at", None) is not None
                        else None
                    ),
                    "end_at": (
                        getattr(item, "end_at", None).isoformat()
                        if getattr(item, "end_at", None) is not None
                        else None
                    ),
                }
                for item in discounts
            ],
            "actions": actions,
        }

    @staticmethod
    def _generate_discount_reply(
        db: Session,
        conversation: Conversation,
        user_message_id: int,
        cleaned_content: str,
    ) -> Message:
        requested_code = ChatbotService._extract_discount_code(cleaned_content)
        normalized_content = ChatbotService._normalize_text(cleaned_content)
        discounts: List[Any] = []
        source = "general"

        target_categories = ChatbotCatalogService.resolve_categories_from_query(db, cleaned_content)
        target_category_ids = [
            item.id for item in target_categories if getattr(item, "id", None) is not None
        ]
        target_category_label = ", ".join(
            str(getattr(item, "name", "") or "").strip()
            for item in target_categories
            if str(getattr(item, "name", "") or "").strip()
        )

        if requested_code is not None:
            discount = DiscountRepositoryImpl(db).get_valid_by_name(requested_code)
            if not discount:
                return ChatService.create_bot_message(
                    db=db,
                    conversation_id=conversation.id,
                    content=(
                        f"Mình chưa tìm thấy mã giảm giá `{requested_code.upper()}` còn hiệu lực. "
                        "Bạn có thể kiểm tra lại mã hoặc mở kho voucher để xem các mã đang áp dụng."
                    ),
                    reply_to_message_id=user_message_id,
                )
            discounts = [discount]
            source = "code"
        elif target_category_ids:
            discounts = DiscountRepositoryImpl(db).list_valid_for_categories(
                target_category_ids,
                settings.CHATBOT_MAX_PRODUCTS,
            )
            source = "query_category"
        elif "gio hang" in normalized_content:
            cart = CartRepositoryImpl(db).get_cart_response(conversation.user_id)
            cart_category_ids = list(
                {
                    int(category_id)
                    for detail in getattr(cart, "cart_details", []) or []
                    for category_id in [
                        getattr(
                            getattr(getattr(detail, "product_detail", None), "product", None),
                            "category_id",
                            None,
                        )
                    ]
                    if isinstance(category_id, int)
                }
            )
            discounts = DiscountRepositoryImpl(db).list_valid_for_categories(
                cart_category_ids,
                settings.CHATBOT_MAX_PRODUCTS,
            )
            source = "cart"
        elif "ap dung cho" in normalized_content:
            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=(
                    "Mình chưa xác định được nhóm sản phẩm bạn muốn hỏi. "
                    "Bạn hãy nêu rõ như nón 1/2, 3/4 hoặc fullface."
                ),
                reply_to_message_id=user_message_id,
            )
        else:
            discounts = DiscountRepositoryImpl(db).get_active_discounts(
                settings.CHATBOT_MAX_PRODUCTS,
                None,
            )
            source = "system"

        discounts = sorted(
            discounts,
            key=lambda item: (
                -float(getattr(item, "percent", 0) or 0),
                getattr(item, "end_at", None) or getattr(item, "start_at", None),
                -int(getattr(item, "id", 0) or 0),
            ),
        )[: settings.CHATBOT_MAX_PRODUCTS]

        if not discounts:
            if source == "query_category" and target_category_label:
                content = f"Hiện chưa có mã giảm giá nào còn hiệu lực cho {target_category_label}."
            elif source == "cart":
                content = "Hiện chưa có mã giảm giá nào còn hiệu lực áp dụng cho giỏ hàng của bạn."
            else:
                content = "Hiện chưa có mã giảm giá nào còn hiệu lực trong hệ thống."

            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=content,
                reply_to_message_id=user_message_id,
            )

        actions = [
            {
                "type": "open_vouchers",
                "label": "Xem kho voucher",
                "target": "/profile/vouchers",
            }
        ]
        if source == "cart":
            actions.insert(
                0,
                {
                    "type": "open_cart",
                    "label": "Mở giỏ hàng",
                    "target": "/cart",
                },
            )

        first_discount = discounts[0]
        first_category_name = getattr(getattr(first_discount, "category", None), "name", None)

        if requested_code is not None:
            content = (
                f"Mã giảm giá {getattr(first_discount, 'name', '').upper()} đang còn hiệu lực. "
                f"Ưu đãi hiện tại là giảm {float(getattr(first_discount, 'percent', 0) or 0):g}%"
                + (
                    f" cho danh mục {first_category_name}."
                    if (first_category_name or "").strip()
                    else "."
                )
            )
            title = f"Mã giảm giá {getattr(first_discount, 'name', '').upper()}"
        elif source == "query_category":
            content = (
                f"Các mã còn hiệu lực cho {target_category_label}: "
                f"{ChatbotService._format_discount_names(discounts)}."
            )
            title = f"Mã giảm giá cho {target_category_label}"
        elif source == "cart":
            content = (
                f"Giỏ hàng của bạn hiện có {len(discounts)} mã giảm giá còn hiệu lực có thể áp dụng: "
                f"{ChatbotService._format_discount_names(discounts)}."
            )
            title = "Mã giảm giá cho giỏ hàng"
        else:
            content = (
                f"Hiện hệ thống đang có {len(discounts)} mã giảm giá còn hiệu lực: "
                f"{ChatbotService._format_discount_names(discounts)}."
            )
            title = "Mã giảm giá đang áp dụng"

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=content,
            payload=ChatbotService._build_discount_payload(
                discounts=discounts,
                title=title,
                actions=actions,
            ),
            reply_to_message_id=user_message_id,
        )


    @staticmethod
    def _generate_order_reply(
        db: Session,
        conversation: Conversation,
        user_message_id: int,
        cleaned_content: str,
    ) -> Message:
        if ChatbotService._is_recent_order_discount_query(cleaned_content):
            order = OrderRepositoryImpl(db).get_latest_order(conversation.user_id)
            if not order:
                return ChatService.create_bot_message(
                    db=db,
                    conversation_id=conversation.id,
                    content="Mình chưa tìm thấy đơn hàng nào gần đây của bạn.",
                    reply_to_message_id=user_message_id,
                )

            applied_discounts = list(getattr(order, "applied_discounts", []) or [])
            payload = ChatbotService._build_order_payload(order)

            if not applied_discounts:
                content = f"Đơn hàng gần nhất #{order.id} hiện không có mã giảm giá nào được áp dụng."
            else:
                content = (
                    f"Đơn hàng gần nhất #{order.id} đang áp dụng "
                    f"{ChatbotService._format_discount_names(applied_discounts)}."
                )

            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=content,
                payload=payload,
                reply_to_message_id=user_message_id,
            )

        if ChatbotService._is_recent_order_total_query(cleaned_content):
            order = OrderRepositoryImpl(db).get_latest_order(conversation.user_id)
            if not order:
                return ChatService.create_bot_message(
                    db=db,
                    conversation_id=conversation.id,
                    content="Mình chưa tìm thấy đơn hàng nào gần đây của bạn.",
                    reply_to_message_id=user_message_id,
                )

            payload = ChatbotService._build_order_payload(order)
            total_amount = ((payload.get("order") or {}).get("total_amount") or 0)

            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=(
                    f"Đơn hàng gần nhất của bạn là #{order.id}, "
                    f"tổng thanh toán {ChatbotService._format_currency(total_amount)}."
                ),
                payload=payload,
                reply_to_message_id=user_message_id,
            )

        requested_order_id = ChatbotService._extract_order_id(cleaned_content)
        order = None

        if requested_order_id is not None:
            order = OrderRepositoryImpl(db).get_user_order_by_id(conversation.user_id, requested_order_id)
        else:
            orders = OrderRepositoryImpl(db).get_user_orders(conversation.user_id)
            if orders:
                order = orders[0]

        if not order:
            fallback_text = (
                f"Mình chưa tìm thấy đơn #{requested_order_id} của bạn."
                if requested_order_id is not None
                else "Mình chưa tìm thấy đơn hàng nào gần đây của bạn."
            )
            return ChatService.create_bot_message(
                db=db,
                conversation_id=conversation.id,
                content=f"{fallback_text} Bạn có thể gửi mã đơn hàng để mình kiểm tra chính xác hơn.",
                reply_to_message_id=user_message_id,
            )

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=ChatbotService._build_order_message(order, requested_order_id),
            payload=ChatbotService._build_order_payload(order),
            reply_to_message_id=user_message_id,
        )

    @staticmethod
    def generate_reply_for_message(
        db: Session,
        conversation_id: int,
        user_message_id: int,
    ) -> Optional[Message]:
        if not ChatbotService._is_enabled():
            return None

        msg_repo = MessageRepositoryImpl(db)
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        user_message = msg_repo.get_by_id_with_media(
            user_message_id,
            conversation_id,
        )
        if not user_message:
            return None

        if user_message.user_id != conversation.user_id:
            return None
        if user_message.type != MessageType.TEXT:
            return None
        if user_message.deleted_at is not None:
            return None

        cleaned_content = (user_message.content or "").strip()
        if not cleaned_content:
            return None
        if conversation.status == ConversationStatus.CLOSED:
            return None

        existing_reply = ChatbotService._find_existing_bot_reply(
            msg_repo=msg_repo,
            conversation=conversation,
            user_message_id=user_message_id,
        )
        if existing_reply:
            return existing_reply

        if ChatbotService._should_handoff(cleaned_content):
            return ChatService.activate_handoff(
                db=db,
                conversation_id=conversation_id,
                content="Mình sẽ chuyển cuộc trò chuyện này cho tư vấn viên để hỗ trợ bạn kỹ hơn.",
                notice_message="Tư vấn viên sẽ tham gia cuộc trò chuyện sớm nhất có thể.",
                reply_to_message_id=user_message_id,
            )

        if (
            ChatbotService._is_recent_order_discount_query(cleaned_content)
            or ChatbotService._is_recent_order_total_query(cleaned_content)
        ):
            return ChatbotService._generate_order_reply(
                db=db,
                conversation=conversation,
                user_message_id=user_message_id,
                cleaned_content=cleaned_content,
            )

        if ChatbotService._should_lookup_discount(cleaned_content):
            return ChatbotService._generate_discount_reply(
                db=db,
                conversation=conversation,
                user_message_id=user_message_id,
                cleaned_content=cleaned_content,
            )

        if ChatbotService._should_lookup_order(cleaned_content):
            return ChatbotService._generate_order_reply(
                db=db,
                conversation=conversation,
                user_message_id=user_message_id,
                cleaned_content=cleaned_content,
            )

        candidate_products = ChatbotCatalogService.search_products(
            db=db,
            query=cleaned_content,
            limit=settings.CHATBOT_MAX_PRODUCTS,
        )
        if not candidate_products:
            return None

        recent_messages = ChatbotService._load_recent_messages(
            msg_repo=msg_repo,
            conversation=conversation,
            limit=6,
        )
        llm_reply = OpenAIChatService.generate_product_reply(
            user_message=cleaned_content,
            recent_messages=recent_messages,
            candidate_products=[item["llm_candidate"] for item in candidate_products],
        )
        selected_products = ChatbotService._pick_products_for_reply(
            candidate_products=candidate_products,
            matched_product_ids=llm_reply.get("matched_product_ids") or [],
        )
        if not selected_products:
            return None

        message_text = str(llm_reply.get("message") or "").strip()
        if not message_text:
            message_text = "Mình tìm được một số sản phẩm có thể phù hợp với nhu cầu của bạn."

        return ChatService.create_bot_message(
            db=db,
            conversation_id=conversation.id,
            content=message_text,
            payload=ChatbotService._build_product_payload(
                selected_products=selected_products,
                follow_up_suggestions=llm_reply.get("follow_up_suggestions") or [],
            ),
            reply_to_message_id=user_message_id,
        )
