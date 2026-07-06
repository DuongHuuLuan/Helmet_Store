from datetime import datetime
from typing import Optional

from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.message_mapper import MessageMapper
from app.domain.entities.message_entity import MessageEntity
from app.domain.repositories.message_repository import MessageRepository
from app.infrastructure.database.models.conversation import Conversation
from app.infrastructure.database.models.message import Message, MessageType


class MessageRepositoryImpl(MessageRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[MessageEntity]:
        model = (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.id == id)
            .first()
        )
        if not model:
            return None
        return MessageMapper.to_entity(model)

    def list_by_conversation_id(self, conversation_id: int, cursor: Optional[int] = None,
                                limit: int = 20) -> tuple[list[MessageEntity], Optional[int]]:
        limit = max(1, min(limit, 50))
        query = (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.conversation_id == conversation_id)
        )
        if cursor:
            query = query.filter(Message.id < cursor)

        models = query.order_by(Message.id.desc()).limit(limit).all()
        next_cursor = models[-1].id if len(models) == limit else None
        models.reverse()
        entities = [MessageMapper.to_entity(m) for m in models]
        return entities, next_cursor

    def create(self, data: dict) -> MessageEntity:
        create_data = data.copy()
        if "type" in create_data and isinstance(create_data["type"], str):
            create_data["type"] = MessageType(create_data["type"])
        model = Message(**create_data)
        self.db.add(model)
        self.db.flush()
        self.db.refresh(model)
        return MessageMapper.to_entity(model)

    def create_bulk(self, data_list: list[dict]) -> list[MessageEntity]:
        models = []
        for data in data_list:
            create_data = data.copy()
            if "type" in create_data and isinstance(create_data["type"], str):
                create_data["type"] = MessageType(create_data["type"])
            model = Message(**create_data)
            self.db.add(model)
            models.append(model)
        self.db.flush()
        for model in models:
            self.db.refresh(model)
        return [MessageMapper.to_entity(m) for m in models]

    def soft_delete(self, id: int) -> MessageEntity:
        model = (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.id == id)
            .first()
        )
        if not model:
            return None
        model.deleted_at = datetime.utcnow()
        model.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(model)
        return MessageMapper.to_entity(model)

    def get_latest_message_id(self, conversation_id: int, exclude_user_id: int,
                               max_id: Optional[int] = None) -> Optional[int]:
        query = self.db.query(Message.id).filter(
            Message.conversation_id == conversation_id,
            Message.deleted_at.is_(None),
            Message.user_id != exclude_user_id,
        )
        if max_id is not None:
            query = query.filter(Message.id <= max_id)
        row = query.order_by(Message.id.desc()).first()
        return row[0] if row else None

    def get_latest_message_for_conversation(self, conversation_id: int) -> Optional[MessageEntity]:
        model = (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.id.desc())
            .first()
        )
        if not model:
            return None
        return MessageMapper.to_entity(model)

    def count_unread(self, conversation_id: int, exclude_user_id: int,
                      last_read_id: Optional[int]) -> int:
        query = self.db.query(func.count(Message.id)).filter(
            Message.conversation_id == conversation_id,
            Message.deleted_at.is_(None),
            Message.user_id != exclude_user_id,
        )
        if last_read_id is not None:
            query = query.filter(Message.id > last_read_id)
        return query.scalar() or 0

    def count_unread_bulk(self, conversation_ids: list[int], exclude_user_id: int,
                           last_read_map: dict[int, Optional[int]]) -> dict[int, int]:
        if not conversation_ids:
            return {}

        filters = []
        for cid in conversation_ids:
            lrid = last_read_map.get(cid)
            if lrid is not None:
                filters.append(
                    (Message.conversation_id == cid) & (Message.id > lrid)
                )
            else:
                filters.append(Message.conversation_id == cid)

        rows = (
            self.db.query(
                Message.conversation_id,
                func.count(Message.id).label("unread_count"),
            )
            .filter(
                Message.deleted_at.is_(None),
                Message.user_id != exclude_user_id,
                or_(*filters),
            )
            .group_by(Message.conversation_id)
            .all()
        )

        result = {row.conversation_id: row.unread_count for row in rows}
        for cid in conversation_ids:
            result.setdefault(cid, 0)
        return result

    def get_recent_messages(self, conversation_id: int, limit: int,
                            exclude_deleted: bool = True) -> list:
        query = (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.conversation_id == conversation_id)
        )
        if exclude_deleted:
            query = query.filter(Message.deleted_at.is_(None))
        return query.order_by(Message.id.desc()).limit(limit).all()

    def find_existing_bot_reply(self, conversation_id: int, admin_id: int,
                                user_message_id: int):
        return (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.conversation_id == conversation_id,
                Message.user_id == admin_id,
                Message.type == MessageType.SYSTEM,
                Message.deleted_at.is_(None),
                Message.id > user_message_id,
            )
            .order_by(Message.id.asc())
            .all()
        )

    def get_by_id_with_media(self, message_id: int, conversation_id: int):
        return (
            self.db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.id == message_id,
                Message.conversation_id == conversation_id,
            )
            .first()
        )
