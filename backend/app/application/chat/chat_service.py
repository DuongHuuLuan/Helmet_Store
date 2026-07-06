import json
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import cloudinary.uploader
from fastapi import HTTPException, UploadFile
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.models import Conversation, Message, MessageMedia, User
from app.infrastructure.database.models.conversation import ConversationStatus
from app.infrastructure.database.models.message import MessageType
from app.infrastructure.database.models.message_media import MessageMediaType
from app.infrastructure.database.models.user import UserRole
from app.core.config import settings
from app.infrastructure.repositories.conversation_repository_impl import ConversationRepositoryImpl
from app.infrastructure.repositories.message_repository_impl import MessageRepositoryImpl
from app.infrastructure.repositories.notification_outbox_repository_impl import NotificationOutboxRepositoryImpl
from app.infrastructure.repositories.user_device_repository_impl import UserDeviceRepositoryImpl
from app.infrastructure.websocket.manager import chat_ws_manager


class ChatService:
    RECALLED_MESSAGE_PLACEHOLDER = "Tin nhắn đã được thu hồi"

    @staticmethod
    def _assert_member(conversation: Conversation, user: User) -> None:
        if user.id not in (conversation.user_id, conversation.admin_id):
            raise HTTPException(status_code=403, detail="You are not a member of this conversation")

    @staticmethod
    def _pick_default_admin(db: Session) -> User:
        admin = (
            db.query(User)
            .filter(User.role == UserRole.ADMIN)
            .order_by(User.id.asc())
            .first()
        )
        if not admin:
            raise HTTPException(status_code=400, detail="No admin account is available for chat")
        return admin

    @staticmethod
    def _get_actor_read_field_name(current_user: User) -> str:
        if current_user.role == UserRole.ADMIN:
            return "last_read_admin_message_id"
        return "last_read_user_message_id"

    @staticmethod
    def _get_actor_last_read_message_id(conversation: Conversation, current_user: User) -> Optional[int]:
        return getattr(conversation, ChatService._get_actor_read_field_name(current_user))

    @staticmethod
    def _serialize_conversation(
        conversation: Conversation,
        current_user: User,
        unread_count: int = 0,
    ) -> dict:
        return {
            "id": conversation.id,
            "user_id": conversation.user_id,
            "admin_id": conversation.admin_id,
            "user": ChatService._serialize_user_summary(conversation.user),
            "status": conversation.status,
            "last_message_id": conversation.last_message_id,
            "last_read_user_message_id": conversation.last_read_user_message_id,
            "last_read_admin_message_id": conversation.last_read_admin_message_id,
            "last_read_message_id": ChatService._get_actor_last_read_message_id(conversation, current_user),
            "unread_count": unread_count,
            "last_message_at": conversation.last_message_at,
            "created_at": conversation.created_at,
            "updated_at": conversation.updated_at,
        }

    @staticmethod
    def _serialize_user_summary(user: Optional[User]) -> Optional[dict]:
        if not user:
            return None
        profile = user.profile
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "profile": {
                "name": profile.name if profile else None,
                "phone": profile.phone if profile else None,
                "avatar": profile.avatar if profile else None,
            } if profile else None,
        }

    @staticmethod
    def get_conversation_with_user(db: Session, conversation_id: int) -> Optional[Conversation]:
        return (
            db.query(Conversation)
            .options(joinedload(Conversation.user).joinedload(User.profile))
            .filter(Conversation.id == conversation_id)
            .first()
        )

    @staticmethod
    def _get_unread_counts(
        db: Session,
        conversations: List[Conversation],
        current_user: User,
    ) -> dict[int, int]:
        if not conversations:
            return {}

        msg_repo = MessageRepositoryImpl(db)
        conversation_ids = [c.id for c in conversations]
        read_field = (
            "last_read_admin_message_id"
            if current_user.role == UserRole.ADMIN
            else "last_read_user_message_id"
        )
        last_read_map = {c.id: getattr(c, read_field) for c in conversations}
        return msg_repo.count_unread_bulk(
            conversation_ids=conversation_ids,
            exclude_user_id=current_user.id,
            last_read_map=last_read_map,
        )

    @staticmethod
    def build_conversation_out(
        db: Session,
        conversation: Conversation,
        current_user: User,
    ) -> dict:
        unread_count = ChatService._get_unread_counts(db, [conversation], current_user).get(conversation.id, 0)
        return ChatService._serialize_conversation(conversation, current_user, unread_count)

    @staticmethod
    def _serialize_message_media(media: MessageMedia) -> dict:
        return {
            "id": media.id,
            "path": media.path,
            "media_type": media.media_type,
            "created_at": media.created_at,
        }

    @staticmethod
    def _parse_message_metadata(message: Message) -> Dict[str, Any]:
        raw = getattr(message, "metadata_json", None)
        if not raw:
            return {}
        if isinstance(raw, dict):
            return raw
        if isinstance(raw, str):
            try:
                parsed = json.loads(raw)
            except (TypeError, ValueError, json.JSONDecodeError):
                return {}
            return parsed if isinstance(parsed, dict) else {}
        return {}

    @staticmethod
    def serialize_message(message: Message) -> dict:
        is_recalled = message.deleted_at is not None
        metadata = ChatService._parse_message_metadata(message)
        sender_role = metadata.get("sender_role")
        if sender_role is not None:
            sender_role = str(sender_role).strip().lower() or None
        payload = metadata.get("payload")
        if not isinstance(payload, dict):
            payload = None
        return {
            "id": message.id,
            "conversation_id": message.conversation_id,
            "user_id": message.user_id,
            "type": message.type,
            "client_msg_id": message.client_msg_id,
            "sender_role": sender_role,
            "content": (
                ChatService.RECALLED_MESSAGE_PLACEHOLDER
                if is_recalled
                else message.content
            ),
            "payload": None if is_recalled else payload,
            "created_at": message.created_at,
            "media_items": (
                []
                if is_recalled
                else [
                    ChatService._serialize_message_media(media)
                    for media in (message.media_items or [])
                ]
            ),
            "is_recalled": is_recalled,
            "recalled_at": message.deleted_at,
        }

    @staticmethod
    def _guess_media_type_from_upload(file: UploadFile) -> MessageMediaType:
        content_type = (file.content_type or "").lower()
        if content_type.startswith("image/"):
            return MessageMediaType.IMAGE
        if content_type.startswith("video/"):
            return MessageMediaType.VIDEO
        if content_type.startswith("audio/"):
            return MessageMediaType.AUDIO
        return MessageMediaType.FILE

    @staticmethod
    def get_or_create_conversation(db: Session, user_id: int, admin_id: int) -> Conversation:
        user = ChatService.get_or_404(db, User, user_id, "User not found")
        admin = ChatService.get_or_404(db, User, admin_id, "Admin not found")
        if user.role != UserRole.USER:
            raise HTTPException(status_code=400, detail="Invalid user_id")
        if admin.role != UserRole.ADMIN:
            raise HTTPException(status_code=400, detail="Invalid admin_id")

        convo_repo = ConversationRepositoryImpl(db)
        entity = convo_repo.create_or_get(user_id=user_id, admin_id=admin_id)
        return ChatService.get_conversation_with_user(db, entity.id)

    @staticmethod
    def create_or_get_for_actor(
        db: Session,
        current_user: User,
        user_id: Optional[int] = None,
        admin_id: Optional[int] = None,
    ) -> Conversation:
        if current_user.role == UserRole.ADMIN:
            if user_id is None:
                raise HTTPException(status_code=400, detail="Admin must provide user_id to open chat")
            return ChatService.get_or_create_conversation(db=db, user_id=user_id, admin_id=current_user.id)
        if current_user.role == UserRole.USER:
            target_admin_id = admin_id
            if target_admin_id is None:
                target_admin_id = ChatService._pick_default_admin(db).id
            return ChatService.get_or_create_conversation(db=db, user_id=current_user.id, admin_id=target_admin_id)
        raise HTTPException(status_code=403, detail="You do not have permission to create a conversation")

    @staticmethod
    def list_conversations(db: Session, current_user: User) -> List[dict]:
        query = db.query(Conversation).options(
            joinedload(Conversation.user).joinedload(User.profile)
        )
        if current_user.role == UserRole.ADMIN:
            query = query.filter(Conversation.admin_id == current_user.id)
        else:
            query = query.filter(Conversation.user_id == current_user.id)
        conversations = query.order_by(
            func.coalesce(Conversation.last_message_at, Conversation.created_at).desc()
        ).all()
        unread_map = ChatService._get_unread_counts(db, conversations, current_user)
        return [
            ChatService._serialize_conversation(
                conversation=conversation,
                current_user=current_user,
                unread_count=unread_map.get(conversation.id, 0),
            )
            for conversation in conversations
        ]

    @staticmethod
    def list_messages(
        db: Session,
        conversation_id: int,
        current_user: User,
        cursor: Optional[int] = None,
        limit: int = 20,
    ) -> Tuple[List[Message], Optional[int]]:
        convo_repo = ConversationRepositoryImpl(db)
        conversation = convo_repo.get_by_id(conversation_id)
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation not found")
        ChatService._assert_member(
            db.query(Conversation).filter(Conversation.id == conversation_id).first(),
            current_user,
        )

        msg_repo = MessageRepositoryImpl(db)
        entities, next_cursor = msg_repo.list_by_conversation_id(
            conversation_id=conversation_id,
            cursor=cursor,
            limit=limit,
        )
        models = (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.id.in_([e.id for e in entities]))
            .order_by(Message.id.asc())
            .all()
        )
        return models, next_cursor

    @staticmethod
    def send_message_with_uploads(
        db: Session,
        conversation_id: int,
        current_user: User,
        files: Optional[List[UploadFile]] = None,
        content: Optional[str] = None,
        client_msg_id: Optional[str] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        ChatService._assert_member(conversation, current_user)
        cleaned_content = (content or "").strip()
        if not files and not cleaned_content:
            raise HTTPException(status_code=400, detail="Message content cannot be empty")

        msg_repo = MessageRepositoryImpl(db)

        if client_msg_id:
            existed_model = (
                db.query(Message)
                .options(joinedload(Message.media_items))
                .filter(
                    Message.user_id == current_user.id,
                    Message.client_msg_id == client_msg_id,
                )
                .first()
            )
            if existed_model:
                return existed_model

        uploaded_items = []
        uploaded_public_ids: List[str] = []
        try:
            for file in files or []:
                upload_result = cloudinary.uploader.upload(
                    file.file,
                    folder="helmet_shop/chat",
                    resource_type="auto",
                )
                uploaded_items.append({
                    "path": upload_result["secure_url"],
                    "media_type": ChatService._guess_media_type_from_upload(file),
                })
                if upload_result.get("public_id"):
                    uploaded_public_ids.append(upload_result["public_id"])

            if uploaded_items:
                if all(item["media_type"] == MessageMediaType.IMAGE for item in uploaded_items):
                    message_type = MessageType.IMAGE
                else:
                    message_type = MessageType.FILE
            else:
                message_type = MessageType.TEXT

            message = Message(
                conversation_id=conversation_id,
                user_id=current_user.id,
                type=message_type,
                content=cleaned_content if cleaned_content else None,
                client_msg_id=client_msg_id,
            )
            db.add(message)
            db.flush()

            for item in uploaded_items:
                db.add(MessageMedia(
                    message_id=message.id,
                    path=item["path"],
                    media_type=item["media_type"],
                ))

            conversation.last_message_id = message.id
            conversation.last_message_at = datetime.utcnow()

            receiver_user_id = (
                conversation.admin_id
                if current_user.id == conversation.user_id
                else conversation.user_id
            )
            if not chat_ws_manager.has_user_connection(
                conversation_id=conversation.id,
                user_id=receiver_user_id,
            ):
                ChatService._enqueue_chat_notification(
                    db=db, conversation=conversation, message=message,
                    receiver_user_id=receiver_user_id,
                )

            db.commit()

            return (
                db.query(Message)
                .options(joinedload(Message.media_items))
                .filter(Message.id == message.id)
                .first()
            )
        except Exception:
            db.rollback()
            for public_id in uploaded_public_ids:
                try:
                    cloudinary.uploader.destroy(public_id, invalidate=True)
                except Exception:
                    pass
            raise

    @staticmethod
    def _enqueue_chat_notification(
        db: Session,
        conversation: Conversation,
        message: Message,
        receiver_user_id: int,
    ) -> None:
        device_repo = UserDeviceRepositoryImpl(db)
        if not device_repo.has_active_device(receiver_user_id):
            return

        dedupe_key = f"chat_message_{message.id}_to_{receiver_user_id}"
        outbox_repo = NotificationOutboxRepositoryImpl(db)
        existed = outbox_repo.get_by_dedupe_key(dedupe_key)
        if existed:
            return

        if message.content and message.content.strip():
            body = message.content.strip()[:180]
        elif message.type == MessageType.IMAGE:
            body = "Bạn vừa nhận ảnh mới"
        elif message.type == MessageType.FILE:
            body = "Bạn vừa nhận tệp mới"
        else:
            body = "Bạn có tin nhắn mới"

        payload = {
            "title": "Tin nhắn mới",
            "body": body,
            "data": {
                "event": "chat.message.created",
                "conversation_id": conversation.id,
                "message_id": message.id,
                "sender_id": message.user_id,
                "receiver_id": receiver_user_id,
                "type": message.type.value,
            },
        }
        payload_str = json.dumps(payload, ensure_ascii=False)

        outbox_repo.create({
            "user_id": receiver_user_id,
            "conversation_id": conversation.id,
            "message_id": message.id,
            "event_type": "chat.message.created",
            "payload": payload_str,
            "dedupe_key": dedupe_key,
            "status": "pending",
            "retry_count": 0,
            "max_retry": settings.PUSH_OUTBOX_MAX_RETRY,
        })

    @staticmethod
    def _create_automated_message(
        db: Session,
        conversation: Conversation,
        *,
        sender_role: str,
        actor_user_id: Optional[int],
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        cleaned_content = (content or "").strip()
        if not cleaned_content and payload is None:
            raise HTTPException(status_code=400, detail="Tin nhắn hệ thống không được để trống")

        metadata: Dict[str, Any] = {"sender_role": sender_role}
        if isinstance(payload, dict) and payload:
            metadata["payload"] = payload
        if reply_to_message_id is not None:
            metadata["reply_to_message_id"] = reply_to_message_id

        msg_repo = MessageRepositoryImpl(db)

        try:
            message_data = {
                "conversation_id": conversation.id,
                "user_id": actor_user_id or conversation.admin_id,
                "type": MessageType.SYSTEM.value,
                "content": cleaned_content or None,
                "metadata_json": json.dumps(metadata, ensure_ascii=False),
            }
            entity = msg_repo.create(message_data)

            conversation.last_message_id = entity.id
            conversation.last_message_at = datetime.utcnow()

            if not chat_ws_manager.has_user_connection(
                conversation_id=conversation.id,
                user_id=conversation.user_id,
            ):
                ChatService._enqueue_chat_notification(
                    db=db, conversation=conversation,
                    message=db.query(Message).filter(Message.id == entity.id).first(),
                    receiver_user_id=conversation.user_id,
                )

            db.commit()

            return (
                db.query(Message)
                .options(joinedload(Message.media_items))
                .filter(Message.id == entity.id)
                .first()
            )
        except Exception:
            db.rollback()
            raise

    @staticmethod
    def create_bot_message(
        db: Session,
        conversation_id: int,
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        return ChatService._create_automated_message(
            db=db, conversation=conversation, sender_role="bot",
            actor_user_id=conversation.admin_id, content=content,
            payload=payload, reply_to_message_id=reply_to_message_id,
        )

    @staticmethod
    def create_system_message(
        db: Session,
        conversation_id: int,
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        actor_user_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        return ChatService._create_automated_message(
            db=db, conversation=conversation, sender_role="system",
            actor_user_id=actor_user_id or conversation.admin_id,
            content=content, payload=payload,
        )

    @staticmethod
    def activate_handoff(
        db: Session,
        conversation_id: int,
        content: str,
        notice_message: str,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        convo_repo = ConversationRepositoryImpl(db)
        convo_repo.update_status(id=conversation_id, status=ConversationStatus.CLOSED.value)
        conversation.status = ConversationStatus.CLOSED
        return ChatService._create_automated_message(
            db=db, conversation=conversation, sender_role="bot",
            actor_user_id=conversation.admin_id, content=content,
            payload={
                "kind": "handoff_notice",
                "notice_code": "human_handoff_requested",
                "notice_message": notice_message,
            },
            reply_to_message_id=reply_to_message_id,
        )

    @staticmethod
    def claim_handoff(
        db: Session,
        conversation_id: int,
        current_user: User,
    ) -> Message:
        convo_repo = ConversationRepositoryImpl(db)
        conversation_entity = convo_repo.get_by_id(conversation_id)
        if not conversation_entity:
            raise HTTPException(status_code=404, detail="Conversation not found")
        ChatService._assert_member(
            db.query(Conversation).filter(Conversation.id == conversation_id).first(),
            current_user,
        )
        if current_user.role != UserRole.ADMIN or current_user.id != conversation_entity.admin_id:
            raise HTTPException(status_code=403, detail="Bạn không có quyền tiếp nhận cuộc hội thoại này")

        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()

        if conversation_entity.status == ConversationStatus.OPEN.value:
            convo_repo.update_status(id=conversation_id, status=ConversationStatus.CLOSED.value)
            conversation.status = ConversationStatus.CLOSED
        elif conversation_entity.status != ConversationStatus.CLOSED.value:
            raise HTTPException(status_code=400, detail="Cuộc hội thoại này không thể tiếp nhận lúc này")

        return ChatService._create_automated_message(
            db=db, conversation=conversation, sender_role="system",
            actor_user_id=current_user.id,
            content="Tư vấn viên đã tham gia cuộc trò chuyện và sẽ hỗ trợ bạn trực tiếp.",
            payload={
                "kind": "handoff_notice",
                "notice_code": "human_handoff_claimed",
                "notice_message": "Tư vấn viên đã tiếp nhận cuộc trò chuyện này.",
            },
        )

    @staticmethod
    def resume_chatbot(
        db: Session,
        conversation_id: int,
        current_user: User,
    ) -> Message:
        convo_repo = ConversationRepositoryImpl(db)
        conversation_entity = convo_repo.get_by_id(conversation_id)
        if not conversation_entity:
            raise HTTPException(status_code=404, detail="Conversation not found")
        ChatService._assert_member(
            db.query(Conversation).filter(Conversation.id == conversation_id).first(),
            current_user,
        )
        if current_user.role != UserRole.ADMIN or current_user.id != conversation_entity.admin_id:
            raise HTTPException(status_code=403, detail="Bạn không có quyền bật lại trợ lý AI cho cuộc hội thoại này")

        convo_repo.update_status(id=conversation_id, status=ConversationStatus.OPEN.value)
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        conversation.status = ConversationStatus.OPEN

        return ChatService._create_automated_message(
            db=db, conversation=conversation, sender_role="system",
            actor_user_id=current_user.id,
            content="Trợ lý AI đã được bật lại. Bạn có thể tiếp tục hỏi để được hỗ trợ nhanh hơn.",
            payload={
                "kind": "handoff_notice",
                "notice_code": "bot_resumed",
                "notice_message": "Trợ lý AI đã được kích hoạt lại cho cuộc trò chuyện này.",
            },
        )

    @staticmethod
    def recall_message(
        db: Session,
        conversation_id: int,
        message_id: int,
        current_user: User,
    ) -> Message:
        convo_repo = ConversationRepositoryImpl(db)
        conversation_entity = convo_repo.get_by_id(conversation_id)
        if not conversation_entity:
            raise HTTPException(status_code=404, detail="Conversation not found")
        ChatService._assert_member(
            db.query(Conversation).filter(Conversation.id == conversation_id).first(),
            current_user,
        )

        msg_repo = MessageRepositoryImpl(db)
        message_entity = msg_repo.get_by_id(message_id)
        if not message_entity or message_entity.conversation_id != conversation_id:
            raise HTTPException(status_code=404, detail="Message not found")
        if message_entity.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only recall your own messages")

        if message_entity.deleted_at is None:
            msg_repo.soft_delete(message_id)

        return (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.id == message_id)
            .first()
        )

    @staticmethod
    def mark_as_read(
        db: Session,
        conversation_id: int,
        current_user: User,
        message_id: Optional[int] = None,
    ) -> dict:
        convo_repo = ConversationRepositoryImpl(db)
        conversation_entity = convo_repo.get_by_id(conversation_id)
        if not conversation_entity:
            raise HTTPException(status_code=404, detail="Conversation not found")
        ChatService._assert_member(
            db.query(Conversation).filter(Conversation.id == conversation_id).first(),
            current_user,
        )

        msg_repo = MessageRepositoryImpl(db)
        latest_incoming_message_id = msg_repo.get_latest_message_id(
            conversation_id=conversation_id,
            exclude_user_id=current_user.id,
            max_id=message_id,
        )

        read_field_name = ChatService._get_actor_read_field_name(current_user)
        current_read_message_id = getattr(conversation_entity, read_field_name)
        next_read_message_id = current_read_message_id
        changed = False

        if latest_incoming_message_id is not None:
            if current_read_message_id is None or latest_incoming_message_id > current_read_message_id:
                kwargs = {read_field_name: latest_incoming_message_id}
                convo_repo.mark_as_read(id=conversation_id, **kwargs)
                next_read_message_id = latest_incoming_message_id
                changed = True

        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        unread_count = ChatService._get_unread_counts(db, [conversation], current_user).get(conversation.id, 0)
        return {
            "conversation_id": conversation_id,
            "last_read_message_id": next_read_message_id,
            "unread_count": unread_count,
            "changed": changed,
        }
