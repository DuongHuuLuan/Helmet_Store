from app.domain.entities.notification_outbox_entity import NotificationOutboxEntity
from app.infrastructure.database.models.push_notification import NotificationOutbox, NotificationOutboxStatus


class NotificationOutboxMapper:
    @staticmethod
    def to_entity(model: NotificationOutbox) -> NotificationOutboxEntity:
        return NotificationOutboxEntity(
            id=model.id,
            user_id=model.user_id,
            conversation_id=model.conversation_id,
            message_id=model.message_id,
            event_type=model.event_type,
            payload=model.payload,
            dedupe_key=model.dedupe_key,
            status=model.status.value if hasattr(model.status, 'value') else model.status,
            retry_count=model.retry_count,
            max_retry=model.max_retry,
            next_retry_at=model.next_retry_at,
            sent_at=model.sent_at,
            last_error=model.last_error,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @staticmethod
    def to_model(entity: NotificationOutboxEntity) -> NotificationOutbox:
        return NotificationOutbox(
            id=entity.id,
            user_id=entity.user_id,
            conversation_id=entity.conversation_id,
            message_id=entity.message_id,
            event_type=entity.event_type,
            payload=entity.payload,
            dedupe_key=entity.dedupe_key,
            status=NotificationOutboxStatus(entity.status) if entity.status else None,
            retry_count=entity.retry_count,
            max_retry=entity.max_retry,
            next_retry_at=entity.next_retry_at,
            sent_at=entity.sent_at,
            last_error=entity.last_error,
        )
