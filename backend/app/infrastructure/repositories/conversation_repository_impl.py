from typing import Optional

from sqlalchemy.orm import Session, joinedload

from app.infrastructure.database.mappers.conversation_mapper import ConversationMapper
from app.domain.entities.conversation_entity import ConversationEntity
from app.domain.repositories.conversation_repository import ConversationRepository
from app.infrastructure.database.models.conversation import Conversation, ConversationStatus
from app.infrastructure.database.models.user import User


class ConversationRepositoryImpl(ConversationRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int) -> Optional[ConversationEntity]:
        model = (
            self.db.query(Conversation)
            .options(
                joinedload(Conversation.user).joinedload(getattr(Conversation.user, 'profile', None)),
            )
            .filter(Conversation.id == id)
            .first()
        )
        if not model:
            return None
        return ConversationMapper.to_entity(model)

    def get_by_user_admin(self, user_id: int, admin_id: int) -> Optional[ConversationEntity]:
        model = (
            self.db.query(Conversation)
            .filter(
                Conversation.user_id == user_id,
                Conversation.admin_id == admin_id,
            )
            .first()
        )
        if not model:
            return None
        return ConversationMapper.to_entity(model)

    def list_by_user_id(self, user_id: int) -> list[ConversationEntity]:
        models = (
            self.db.query(Conversation)
            .options(joinedload(Conversation.user).joinedload(getattr(Conversation.user, 'profile', None)))
            .filter(Conversation.user_id == user_id)
            .order_by(
                Conversation.last_message_at.desc(),
                Conversation.created_at.desc(),
            )
            .all()
        )
        return [ConversationMapper.to_entity(m) for m in models]

    def list_by_admin_id(self, admin_id: int) -> list[ConversationEntity]:
        models = (
            self.db.query(Conversation)
            .options(joinedload(Conversation.user).joinedload(getattr(Conversation.user, 'profile', None)))
            .filter(Conversation.admin_id == admin_id)
            .order_by(
                Conversation.last_message_at.desc(),
                Conversation.created_at.desc(),
            )
            .all()
        )
        return [ConversationMapper.to_entity(m) for m in models]

    def create(self, data: dict) -> ConversationEntity:
        model = Conversation(**data)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ConversationMapper.to_entity(model)

    def update(self, id: int, data: dict) -> ConversationEntity:
        model = self.db.query(Conversation).filter(Conversation.id == id).first()
        if not model:
            return None
        for key, value in data.items():
            if key == "status" and isinstance(value, str):
                value = ConversationStatus(value)
            setattr(model, key, value)
        self.db.commit()
        self.db.refresh(model)
        return ConversationMapper.to_entity(model)

    def mark_as_read(self, id: int, last_read_user_message_id: Optional[int] = None,
                     last_read_admin_message_id: Optional[int] = None) -> Optional[ConversationEntity]:
        model = self.db.query(Conversation).filter(Conversation.id == id).first()
        if not model:
            return None
        if last_read_user_message_id is not None:
            model.last_read_user_message_id = last_read_user_message_id
        if last_read_admin_message_id is not None:
            model.last_read_admin_message_id = last_read_admin_message_id
        self.db.commit()
        self.db.refresh(model)
        return ConversationMapper.to_entity(model)

    def update_status(self, id: int, status: str) -> Optional[ConversationEntity]:
        model = self.db.query(Conversation).filter(Conversation.id == id).first()
        if not model:
            return None
        model.status = ConversationStatus(status)
        self.db.commit()
        self.db.refresh(model)
        return ConversationMapper.to_entity(model)

    def get_conversation_with_user(self, id: int) -> Optional[ConversationEntity]:
        model = (
            self.db.query(Conversation)
            .options(joinedload(Conversation.user).joinedload(User.profile))
            .filter(Conversation.id == id)
            .first()
        )
        if not model:
            return None
        return ConversationMapper.to_entity(model)

    def create_or_get(self, user_id: int, admin_id: int) -> ConversationEntity:
        model = self.db.query(Conversation).filter(
            Conversation.user_id == user_id,
            Conversation.admin_id == admin_id,
        ).first()
        if model:
            return ConversationMapper.to_entity(model)

        model = Conversation(user_id=user_id, admin_id=admin_id)
        self.db.add(model)
        self.db.commit()
        self.db.refresh(model)
        return ConversationMapper.to_entity(model)
