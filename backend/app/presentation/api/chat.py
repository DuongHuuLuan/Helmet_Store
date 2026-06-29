import logging
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, BackgroundTasks, Body, Depends, File, Form, HTTPException, Query, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.encoders import jsonable_encoder
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.presentation.api.deps import require_user
from app.core.config import settings
from app.infrastructure.database.session import SessionLocal
from app.infrastructure.database.models import Conversation, ProductDetail
from app.domain.entities.user_entity import UserEntity as User
from app.infrastructure.database.models.user import UserRole
from app.application.dto.cart_dto import CartDetailCreate
from app.application.dto.chat_dto import (
    ConversationCreateIn,
    ConversationOut,
    ConversationReadIn,
    ConversationReadOut,
    MessageListOut,
    MessageOut,
)
from app.application._image_utils import pick_primary_image
from app.infrastructure.repositories.cart_repository_impl import CartRepositoryImpl
from app.application.chat.bot_service import ChatbotService
from app.application.chat.chat_service import ChatService
from app.infrastructure.websocket.manager import chat_ws_manager
from app.shared.dependencies import (
    get_list_conversations_use_case,
    get_create_conversation_use_case,
    get_list_messages_use_case,
    get_recall_message_use_case,
    get_mark_read_use_case,
    get_claim_handoff_use_case,
    get_resume_chatbot_use_case,
)
from app.application.use_case.chat.list_conversations_usecase import ListConversationsUseCase
from app.application.use_case.chat.create_conversation_usecase import CreateConversationUseCase
from app.application.use_case.chat.list_messages_usecase import ListMessagesUseCase
from app.application.use_case.chat.recall_message_usecase import RecallMessageUseCase
from app.application.use_case.chat.mark_read_usecase import MarkReadUseCase
from app.application.use_case.chat.claim_handoff_usecase import ClaimHandoffUseCase
from app.application.use_case.chat.resume_chatbot_usecase import ResumeChatbotUseCase


router = APIRouter(prefix="/chat", tags=["Chat"])
logger = logging.getLogger(__name__)


def _normalize_ws_token(token: str) -> str:
    raw = token.strip()
    if raw.lower().startswith("bearer "):
        return raw.split(" ", 1)[1].strip()
    return raw


def _get_ws_user_from_token(db: Session, token: str) -> Optional[User]:
    normalized_token = _normalize_ws_token(token)
    try:
        payload = jwt.decode(normalized_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            return None
    except JWTError:
        return None

    try:
        parsed_user_id = int(user_id)
    except (TypeError, ValueError):
        return None

    return db.query(User).filter(User.id == parsed_user_id).first()


def _message_new_payload(conversation_id: int, message_out: MessageOut) -> Dict[str, Any]:
    return {
        "event": "message:new",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
    }


def _message_recalled_payload(conversation_id: int, message_out: MessageOut) -> Dict[str, Any]:
    return {
        "event": "message:recalled",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
    }


def _message_read_payload(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> Dict[str, Any]:
    return {
        "event": "message:read",
        "conversation_id": conversation_id,
        "user_id": user_id,
        "data": jsonable_encoder(read_out),
    }


def _build_message_out(message) -> MessageOut:
    return MessageOut.model_validate(ChatService.serialize_message(message))


def _create_message(
    conversation_id: int,
    user_id: int,
    files: Optional[List[UploadFile]],
    content: Optional[str],
    client_msg_id: Optional[str],
) -> MessageOut:
    db = SessionLocal()
    try:
        current_user = db.query(User).filter(User.id == user_id).first()
        if not current_user:
            raise HTTPException(status_code=401, detail="Invalid user")

        message = ChatService.send_message_with_uploads(
            db=db,
            conversation_id=conversation_id,
            current_user=current_user,
            files=files,
            content=content,
            client_msg_id=client_msg_id,
        )
        return _build_message_out(message)
    finally:
        db.close()


def _create_chatbot_message(
    conversation_id: int,
    user_message_id: int,
) -> Optional[MessageOut]:
    db = SessionLocal()
    try:
        message = ChatbotService.generate_reply_for_message(
            db=db,
            conversation_id=conversation_id,
            user_message_id=user_message_id,
        )
        if not message:
            return None
        return _build_message_out(message)
    finally:
        db.close()


def _mark_conversation_read_ws(
    conversation_id: int,
    user_id: int,
    message_id: Optional[int] = None,
) -> ConversationReadOut:
    db = SessionLocal()
    try:
        current_user = db.query(User).filter(User.id == user_id).first()
        if not current_user:
            raise HTTPException(status_code=401, detail="Invalid user")
        from app.application.use_case.chat.mark_read_usecase import MarkReadUseCase
        from app.infrastructure.repositories.conversation_repository_impl import ConversationRepositoryImpl
        from app.infrastructure.repositories.message_repository_impl import MessageRepositoryImpl
        use_case = MarkReadUseCase(ConversationRepositoryImpl(db), MessageRepositoryImpl(db))
        read_result = use_case.execute(
            conversation_id=conversation_id,
            current_user=current_user,
            message_id=message_id,
        )
        return ConversationReadOut.model_validate(read_result)
    finally:
        db.close()


def _recall_message(
    conversation_id: int,
    message_id: int,
    current_user: User,
    use_case: RecallMessageUseCase,
) -> MessageOut:
    message = use_case.execute(
        conversation_id=conversation_id,
        message_id=message_id,
        current_user=current_user,
    )
    return _build_message_out(message)


def _mark_conversation_read(
    conversation_id: int,
    current_user: User,
    use_case: MarkReadUseCase,
    message_id: Optional[int] = None,
) -> ConversationReadOut:
    read_result = use_case.execute(
        conversation_id=conversation_id,
        current_user=current_user,
        message_id=message_id,
    )
    return ConversationReadOut.model_validate(read_result)


def _claim_handoff(
    conversation_id: int,
    current_user: User,
    use_case: ClaimHandoffUseCase,
) -> MessageOut:
    message = use_case.execute(
        conversation_id=conversation_id,
        current_user=current_user,
    )
    return _build_message_out(message)


def _resume_chatbot(
    conversation_id: int,
    current_user: User,
    use_case: ResumeChatbotUseCase,
) -> MessageOut:
    message = use_case.execute(
        conversation_id=conversation_id,
        current_user=current_user,
    )
    return _build_message_out(message)


def _add_to_cart_from_chat(
    conversation_id: int,
    user_id: int,
    cart_detail_in: CartDetailCreate,
) -> MessageOut:
    db = SessionLocal()
    try:
        current_user = db.query(User).filter(User.id == user_id).first()
        if not current_user:
            raise HTTPException(status_code=401, detail="Invalid user")
        if current_user.role != UserRole.USER:
            raise HTTPException(status_code=403, detail="Chỉ người dùng mới có thể thêm sản phẩm từ chat")

        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        ChatService._assert_member(conversation, current_user)

        product_detail = ChatService.get_or_404(
            db,
            ProductDetail,
            cart_detail_in.product_detail_id,
            "Sản phẩm không tồn tại",
        )
        product = product_detail.product
        color = getattr(product_detail, "color", None)
        size = getattr(product_detail, "size", None)
        chosen = pick_primary_image(
            list(product.product_images or []),
            color_id=getattr(color, "id", None),
        ) if product else None
        image_url = chosen.url if chosen else None
        variant_bits = [
            bit
            for bit in [
                getattr(color, "name", None),
                getattr(size, "size", None),
            ]
            if bit
        ]
        variant_label = " / ".join(variant_bits) if variant_bits else None
        product_name = getattr(product, "name", None) or "Sản phẩm đã chọn"

        try:
            CartRepositoryImpl(db).add_to_cart(
                current_user.id,
                cart_detail_in.product_detail_id,
                cart_detail_in.design_id,
                cart_detail_in.quantity,
            )
            quantity_label = (
                f"Đã thêm {cart_detail_in.quantity} sản phẩm"
                if cart_detail_in.quantity > 1
                else f"Đã thêm {product_name}"
            )
            if cart_detail_in.quantity > 1 and variant_label:
                content = f"{quantity_label} của biến thể {variant_label} vào giỏ hàng."
            elif variant_label:
                content = f"{quantity_label} - {variant_label} vào giỏ hàng."
            else:
                content = f"{quantity_label} vào giỏ hàng."
            payload = {
                "kind": "cart_action_result",
                "title": "Đã thêm vào giỏ hàng",
                "actions": [
                    {
                        "type": "open_cart",
                        "label": "Xem giỏ hàng",
                        "target": "/cart",
                    }
                ],
                "cart_action_result": {
                    "status": "success",
                    "product_detail_id": cart_detail_in.product_detail_id,
                    "product_name": product_name,
                    "image_url": image_url,
                    "variant_label": variant_label,
                    "quantity": cart_detail_in.quantity,
                    "message": content,
                },
            }
        except HTTPException as exc:
            detail = str(exc.detail).strip() if exc.detail else ""
            content = detail or "Không thể thêm sản phẩm vào giỏ hàng."
            payload = {
                "kind": "cart_action_result",
                "title": "Không thể thêm vào giỏ hàng",
                "cart_action_result": {
                    "status": "error",
                    "product_detail_id": cart_detail_in.product_detail_id,
                    "product_name": product_name,
                    "image_url": image_url,
                    "variant_label": variant_label,
                    "quantity": cart_detail_in.quantity,
                    "message": content,
                },
            }

        message = ChatService.create_system_message(
            db=db,
            conversation_id=conversation_id,
            content=content,
            payload=payload,
            actor_user_id=conversation.admin_id,
        )
        return _build_message_out(message)
    finally:
        db.close()


def _build_admin_conversation_snapshot(conversation_id: int) -> Optional[Tuple[int, Dict[str, Any]]]:
    db = SessionLocal()
    try:
        conversation = ChatService.get_conversation_with_user(db, conversation_id)
        if not conversation:
            return None

        admin = db.query(User).filter(User.id == conversation.admin_id).first()
        if not admin:
            return None

        conversation_out = ChatService.build_conversation_out(
            db=db,
            conversation=conversation,
            current_user=admin,
        )
        return conversation.admin_id, jsonable_encoder(conversation_out)
    finally:
        db.close()


def _build_admin_message_new_payload(
    conversation_id: int,
    message_out: MessageOut,
) -> Optional[Tuple[int, Dict[str, Any]]]:
    snapshot = _build_admin_conversation_snapshot(conversation_id)
    if not snapshot:
        return None

    admin_id, conversation_payload = snapshot
    return admin_id, {
        "event": "message:new",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
        "conversation": conversation_payload,
    }


def _build_admin_message_recalled_payload(
    conversation_id: int,
    message_out: MessageOut,
) -> Optional[Tuple[int, Dict[str, Any]]]:
    snapshot = _build_admin_conversation_snapshot(conversation_id)
    if not snapshot:
        return None

    admin_id, conversation_payload = snapshot
    return admin_id, {
        "event": "message:recalled",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
        "conversation": conversation_payload,
    }


def _build_admin_message_read_payload(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> Optional[Tuple[int, Dict[str, Any]]]:
    snapshot = _build_admin_conversation_snapshot(conversation_id)
    if not snapshot:
        return None

    admin_id, conversation_payload = snapshot
    return admin_id, {
        "event": "message:read",
        "conversation_id": conversation_id,
        "user_id": user_id,
        "data": jsonable_encoder(read_out),
        "conversation": conversation_payload,
    }


async def _broadcast_admin_message_new(conversation_id: int, message_out: MessageOut) -> None:
    payload = await run_in_threadpool(
        _build_admin_message_new_payload,
        conversation_id,
        message_out,
    )
    if not payload:
        return

    admin_id, event_payload = payload
    await chat_ws_manager.broadcast_admin(admin_id=admin_id, payload=event_payload)


async def _broadcast_message_new(conversation_id: int, message_out: MessageOut) -> None:
    await chat_ws_manager.broadcast(
        conversation_id=conversation_id,
        payload=_message_new_payload(
            conversation_id=conversation_id,
            message_out=message_out,
        ),
    )
    await _broadcast_admin_message_new(
        conversation_id=conversation_id,
        message_out=message_out,
    )


async def _broadcast_admin_message_recalled(
    conversation_id: int,
    message_out: MessageOut,
) -> None:
    payload = await run_in_threadpool(
        _build_admin_message_recalled_payload,
        conversation_id,
        message_out,
    )
    if not payload:
        return

    admin_id, event_payload = payload
    await chat_ws_manager.broadcast_admin(admin_id=admin_id, payload=event_payload)


async def _broadcast_admin_message_read(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> None:
    payload = await run_in_threadpool(
        _build_admin_message_read_payload,
        conversation_id,
        user_id,
        read_out,
    )
    if not payload:
        return

    admin_id, event_payload = payload
    await chat_ws_manager.broadcast_admin(admin_id=admin_id, payload=event_payload)


async def _process_chatbot_reply_background(
    conversation_id: int,
    user_message_id: int,
) -> None:
    try:
        chatbot_message_out = await run_in_threadpool(
            _create_chatbot_message,
            conversation_id,
            user_message_id,
        )
    except Exception:
        logger.exception(
            "Không thể tạo tin nhắn chatbot cho conversation_id=%s, user_message_id=%s",
            conversation_id,
            user_message_id,
        )
        return

    if not chatbot_message_out:
        return

    await _broadcast_message_new(
        conversation_id=conversation_id,
        message_out=chatbot_message_out,
    )


# ---- REST Endpoints (migrated to use cases) ----


@router.get("/conversations", response_model=List[ConversationOut])
def get_conversations(
    current_user: User = Depends(require_user),
    use_case: ListConversationsUseCase = Depends(get_list_conversations_use_case),
):
    return use_case.execute(current_user=current_user)


@router.post("/conversations", response_model=ConversationOut)
def create_or_get_conversation(
    payload: ConversationCreateIn,
    current_user: User = Depends(require_user),
    use_case: CreateConversationUseCase = Depends(get_create_conversation_use_case),
):
    return use_case.execute(
        current_user=current_user,
        user_id=payload.user_id,
        admin_id=payload.admin_id,
    )


@router.get("/conversations/{conversation_id}/messages", response_model=MessageListOut)
def get_messages(
    conversation_id: int,
    cursor: Optional[int] = Query(default=None),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: User = Depends(require_user),
    use_case: ListMessagesUseCase = Depends(get_list_messages_use_case),
):
    items, next_cursor = use_case.execute(
        conversation_id=conversation_id,
        current_user=current_user,
        cursor=cursor,
        limit=limit,
    )
    return MessageListOut(
        items=[_build_message_out(item) for item in items],
        next_cursor=next_cursor,
    )


@router.post("/conversations/{conversation_id}/messages", response_model=MessageOut)
async def send_message_with_uploads(
    conversation_id: int,
    background_tasks: BackgroundTasks,
    files: Optional[List[UploadFile]] = File(default=None),
    content: Optional[str] = Form(default=None),
    client_msg_id: Optional[str] = Form(default=None),
    current_user: User = Depends(require_user),
):
    message_out = await run_in_threadpool(
        _create_message,
        conversation_id,
        current_user.id,
        files,
        content,
        client_msg_id,
    )
    await _broadcast_message_new(
        conversation_id=conversation_id,
        message_out=message_out,
    )

    if (
        not settings.CHATBOT_ENABLED
        or current_user.role != UserRole.USER
        or not (message_out.content or "").strip()
    ):
        return message_out

    background_tasks.add_task(
        _process_chatbot_reply_background,
        conversation_id,
        message_out.id,
    )
    return message_out


@router.post("/conversations/{conversation_id}/messages/{message_id}/recall", response_model=MessageOut)
async def recall_message(
    conversation_id: int,
    message_id: int,
    current_user: User = Depends(require_user),
    use_case: RecallMessageUseCase = Depends(get_recall_message_use_case),
):
    message_out = await run_in_threadpool(
        _recall_message,
        conversation_id,
        message_id,
        current_user,
        use_case,
    )
    await chat_ws_manager.broadcast(
        conversation_id=conversation_id,
        payload=_message_recalled_payload(
            conversation_id=conversation_id,
            message_out=message_out,
        ),
    )
    await _broadcast_admin_message_recalled(
        conversation_id=conversation_id,
        message_out=message_out,
    )
    return message_out


@router.post("/conversations/{conversation_id}/read", response_model=ConversationReadOut)
async def mark_conversation_read(
    conversation_id: int,
    payload: Optional[ConversationReadIn] = Body(default=None),
    current_user: User = Depends(require_user),
    use_case: MarkReadUseCase = Depends(get_mark_read_use_case),
):
    read_out = await run_in_threadpool(
        _mark_conversation_read,
        conversation_id,
        current_user,
        use_case,
        payload.message_id if payload else None,
    )
    if read_out.changed:
        await chat_ws_manager.broadcast(
            conversation_id=conversation_id,
            payload=_message_read_payload(
                conversation_id=conversation_id,
                user_id=current_user.id,
                read_out=read_out,
            ),
        )
        await _broadcast_admin_message_read(
            conversation_id=conversation_id,
            user_id=current_user.id,
            read_out=read_out,
        )
    return read_out


@router.post("/conversations/{conversation_id}/handoff/claim", response_model=MessageOut)
async def claim_handoff(
    conversation_id: int,
    current_user: User = Depends(require_user),
    use_case: ClaimHandoffUseCase = Depends(get_claim_handoff_use_case),
):
    message_out = await run_in_threadpool(
        _claim_handoff,
        conversation_id,
        current_user,
        use_case,
    )
    await _broadcast_message_new(
        conversation_id=conversation_id,
        message_out=message_out,
    )
    return message_out


@router.post("/conversations/{conversation_id}/handoff/resume", response_model=MessageOut)
async def resume_chatbot(
    conversation_id: int,
    current_user: User = Depends(require_user),
    use_case: ResumeChatbotUseCase = Depends(get_resume_chatbot_use_case),
):
    message_out = await run_in_threadpool(
        _resume_chatbot,
        conversation_id,
        current_user,
        use_case,
    )
    await _broadcast_message_new(
        conversation_id=conversation_id,
        message_out=message_out,
    )
    return message_out


@router.post("/conversations/{conversation_id}/actions/add-to-cart", response_model=MessageOut)
async def add_to_cart_from_chat(
    conversation_id: int,
    payload: CartDetailCreate,
    current_user: User = Depends(require_user),
):
    message_out = await run_in_threadpool(
        _add_to_cart_from_chat,
        conversation_id,
        current_user.id,
        payload,
    )
    await _broadcast_message_new(
        conversation_id=conversation_id,
        message_out=message_out,
    )
    return message_out


# ---- WebSocket Endpoints (untouched) ----


@router.websocket("/ws/admin")
async def websocket_admin(websocket: WebSocket):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Missing token")
        return

    db = SessionLocal()
    admin_id: Optional[int] = None
    try:
        user = _get_ws_user_from_token(db, token)
        if not user or user.role != UserRole.ADMIN:
            await websocket.close(code=1008, reason="Forbidden")
            return

        admin_id = user.id
    finally:
        db.close()

    await chat_ws_manager.connect_admin(admin_id=admin_id, websocket=websocket)
    try:
        await chat_ws_manager.send_personal(
            websocket,
            {
                "event": "connected",
                "scope": "admin",
                "user_id": admin_id,
            },
        )
        while True:
            try:
                payload = await websocket.receive_json()
            except ValueError:
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_json",
                        "message": "Payload must be valid JSON.",
                    },
                )
                continue

            if not isinstance(payload, dict):
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_payload",
                        "message": "Payload must be a JSON object.",
                    },
                )
                continue

            if payload.get("event") == "ping":
                await chat_ws_manager.send_personal(websocket, {"event": "pong"})
                continue

            await chat_ws_manager.send_personal(
                websocket,
                {
                    "event": "error",
                    "code": "unsupported_event",
                    "message": "Unsupported event.",
                },
            )
    except WebSocketDisconnect:
        chat_ws_manager.disconnect_admin(admin_id, websocket)
    except Exception:
        chat_ws_manager.disconnect_admin(admin_id, websocket)
        try:
            await websocket.close(code=1011)
        except Exception:
            pass


@router.websocket("/ws/conversations/{conversation_id}")
async def websocket_conversation(websocket: WebSocket, conversation_id: int):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Missing token")
        return

    db = SessionLocal()
    user_id: Optional[int] = None
    try:
        user = _get_ws_user_from_token(db, token)
        if not user:
            await websocket.close(code=1008, reason="Invalid token")
            return

        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if not conversation or user.id not in (conversation.user_id, conversation.admin_id):
            await websocket.close(code=1008, reason="Forbidden")
            return

        user_id = user.id
    finally:
        db.close()

    await chat_ws_manager.connect(conversation_id=conversation_id, user_id=user_id, websocket=websocket)
    try:
        await chat_ws_manager.send_personal(
            websocket,
            {
                "event": "connected",
                "conversation_id": conversation_id,
                "user_id": user_id,
            },
        )
        while True:
            try:
                payload = await websocket.receive_json()
            except ValueError:
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_json",
                        "message": "Payload must be valid JSON.",
                    },
                )
                continue

            if not isinstance(payload, dict):
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_payload",
                        "message": "Payload must be a JSON object.",
                    },
                )
                continue

            event = payload.get("event")

            if event == "ping":
                await chat_ws_manager.send_personal(websocket, {"event": "pong"})
                continue

            if event in ("typing:start", "typing:stop"):
                await chat_ws_manager.broadcast(
                    conversation_id=conversation_id,
                    payload={
                        "event": event,
                        "conversation_id": conversation_id,
                        "user_id": user_id,
                    },
                    exclude_user_id=user_id,
                )
                continue

            if event == "message:send":
                data = payload.get("data") or {}
                if not isinstance(data, dict):
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "invalid_payload",
                            "message": "data must be a JSON object.",
                        },
                    )
                    continue

                try:
                    message_out = await run_in_threadpool(
                        _create_message,
                        conversation_id,
                        user_id,
                        None,
                        data.get("content"),
                        data.get("client_msg_id"),
                    )
                except HTTPException as exc:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "message_send_failed",
                            "status_code": exc.status_code,
                            "message": exc.detail,
                        },
                    )
                    continue
                except Exception:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "internal_error",
                            "message": "Unable to process message.",
                        },
                    )
                    continue

                await chat_ws_manager.broadcast(
                    conversation_id=conversation_id,
                    payload=_message_new_payload(conversation_id=conversation_id, message_out=message_out),
                )
                await _broadcast_admin_message_new(
                    conversation_id=conversation_id,
                    message_out=message_out,
                )
                continue

            if event == "message:read":
                data = payload.get("data") or {}
                if not isinstance(data, dict):
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "invalid_payload",
                            "message": "data must be a JSON object.",
                        },
                    )
                    continue

                try:
                    read_out = await run_in_threadpool(
                        _mark_conversation_read_ws,
                        conversation_id,
                        user_id,
                        data.get("message_id"),
                    )
                except HTTPException as exc:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "message_read_failed",
                            "status_code": exc.status_code,
                            "message": exc.detail,
                        },
                    )
                    continue
                except Exception:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "internal_error",
                            "message": "Unable to update read state.",
                        },
                    )
                    continue

                read_payload = _message_read_payload(
                    conversation_id=conversation_id,
                    user_id=user_id,
                    read_out=read_out,
                )
                if read_out.changed:
                    await chat_ws_manager.broadcast(
                        conversation_id=conversation_id,
                        payload=read_payload,
                    )
                    await _broadcast_admin_message_read(
                        conversation_id=conversation_id,
                        user_id=user_id,
                        read_out=read_out,
                    )
                else:
                    await chat_ws_manager.send_personal(websocket, read_payload)
                continue

            await chat_ws_manager.send_personal(
                websocket,
                {
                    "event": "error",
                    "code": "unsupported_event",
                    "message": "Unsupported event.",
                },
            )
    except WebSocketDisconnect:
        chat_ws_manager.disconnect(conversation_id, websocket)
    except Exception:
        chat_ws_manager.disconnect(conversation_id, websocket)
        try:
            await websocket.close(code=1011)
        except Exception:
            pass
