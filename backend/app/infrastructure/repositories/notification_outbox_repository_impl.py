from datetime import datetime
from typing import Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.domain.entities.notification_outbox_entity import NotificationOutboxEntity
from app.domain.repositories.notification_outbox_repository import NotificationOutboxRepository
from app.infrastructure.database.mappers.notification_outbox_mapper import NotificationOutboxMapper
from app.infrastructure.database.models.push_notification import NotificationOutbox, NotificationOutboxStatus


class NotificationOutboxRepositoryImpl(NotificationOutboxRepository):
    def __init__(self, db: Session):
        self.db = db

    def get_by_dedupe_key(self, dedupe_key: str) -> Optional[NotificationOutboxEntity]:
        model = (
            self.db.query(NotificationOutbox)
            .filter(NotificationOutbox.dedupe_key == dedupe_key)
            .first()
        )
        if not model:
            return None
        return NotificationOutboxMapper.to_entity(model)

    def get_by_id(self, id: int) -> Optional[NotificationOutboxEntity]:
        model = (
            self.db.query(NotificationOutbox)
            .filter(NotificationOutbox.id == id)
            .first()
        )
        if not model:
            return None
        return NotificationOutboxMapper.to_entity(model)

    def create(self, data: dict) -> NotificationOutboxEntity:
        model = NotificationOutbox(
            user_id=data.get("user_id"),
            conversation_id=data.get("conversation_id"),
            message_id=data.get("message_id"),
            event_type=data.get("event_type", "chat.message.created"),
            payload=data.get("payload", ""),
            dedupe_key=data.get("dedupe_key"),
            status=NotificationOutboxStatus(data["status"]) if "status" in data else NotificationOutboxStatus.PENDING,
            retry_count=data.get("retry_count", 0),
            max_retry=data.get("max_retry", 5),
            next_retry_at=data.get("next_retry_at"),
            sent_at=data.get("sent_at"),
            last_error=data.get("last_error"),
        )
        self.db.add(model)
        self.db.flush()
        self.db.refresh(model)
        return NotificationOutboxMapper.to_entity(model)

    def list_due_jobs(self, limit: int, now: Optional[datetime] = None) -> list[NotificationOutboxEntity]:
        now = now or datetime.utcnow()
        models = (
            self.db.query(NotificationOutbox)
            .filter(
                NotificationOutbox.status.in_(
                    [NotificationOutboxStatus.PENDING, NotificationOutboxStatus.FAILED]
                ),
                or_(
                    NotificationOutbox.next_retry_at.is_(None),
                    NotificationOutbox.next_retry_at <= now,
                ),
            )
            .order_by(NotificationOutbox.id.asc())
            .limit(max(1, min(limit, 500)))
            .all()
        )
        return [NotificationOutboxMapper.to_entity(m) for m in models]

    def update_status(self, id: int, status: str,
                      error: Optional[str] = None,
                      next_retry_at: Optional[datetime] = None,
                      sent_at: Optional[datetime] = None,
                      retry_count: Optional[int] = None) -> Optional[NotificationOutboxEntity]:
        model = (
            self.db.query(NotificationOutbox)
            .filter(NotificationOutbox.id == id)
            .first()
        )
        if not model:
            return None
        model.status = NotificationOutboxStatus(status)
        if error is not None:
            model.last_error = error
        if next_retry_at is not None:
            model.next_retry_at = next_retry_at
        if sent_at is not None:
            model.sent_at = sent_at
        if retry_count is not None:
            model.retry_count = retry_count
        return NotificationOutboxMapper.to_entity(model)
