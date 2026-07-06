import json
from datetime import datetime, timedelta
from typing import Dict, List

from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.firebase import get_firebase_app
from app.domain.entities.notification_outbox_entity import NotificationOutboxEntity
from app.infrastructure.database.models.push_notification import NotificationOutboxStatus
from app.infrastructure.repositories.notification_outbox_repository_impl import NotificationOutboxRepositoryImpl
from app.infrastructure.repositories.user_device_repository_impl import UserDeviceRepositoryImpl


class PushOutboxService:
    @staticmethod
    def _parse_payload(payload: str) -> Dict:
        try:
            raw = json.loads(payload or "{}")
            return raw if isinstance(raw, dict) else {}
        except Exception:
            return {}

    @staticmethod
    def _serialize_data(data: Dict) -> Dict[str, str]:
        output: Dict[str, str] = {}
        for key, value in (data or {}).items():
            if value is None:
                continue
            output[str(key)] = str(value)
        return output

    @staticmethod
    def _is_invalid_token_error(exc: Exception) -> bool:
        msg = str(exc).lower()
        return (
            "registration-token-not-registered" in msg
            or "not a valid fcm registration token" in msg
            or "requested entity was not found" in msg
            or "unregistered" in msg
        )

    @staticmethod
    def _retry_or_cancel(entity: NotificationOutboxEntity, error: str) -> None:
        now = datetime.utcnow()
        entity.last_error = (error or "")[:500]
        entity.retry_count = (entity.retry_count or 0) + 1

        if entity.retry_count >= (entity.max_retry or settings.PUSH_OUTBOX_MAX_RETRY):
            entity.status = NotificationOutboxStatus.CANCELLED.value
            entity.next_retry_at = None
            return

        delay = settings.PUSH_OUTBOX_RETRY_BASE_SECONDS * (2 ** max(0, entity.retry_count - 1))
        entity.status = NotificationOutboxStatus.FAILED.value
        entity.next_retry_at = now + timedelta(seconds=delay)

    @staticmethod
    def process_due_jobs(db: Session, limit: int = 50) -> int:
        from firebase_admin import messaging

        now = datetime.utcnow()
        batch_size = max(1, min(limit, 500))
        outbox_repo = NotificationOutboxRepositoryImpl(db)
        device_repo = UserDeviceRepositoryImpl(db)

        jobs = outbox_repo.list_due_jobs(batch_size, now)

        processed = 0
        for job in jobs:
            processed += 1
            try:
                outbox_repo.update_status(
                    job.id,
                    status=NotificationOutboxStatus.PROCESSING.value,
                )
                db.commit()

                payload = PushOutboxService._parse_payload(job.payload)
                title = payload.get("title") or "Tin nhắn mới"
                body = payload.get("body") or "Bạn có tin nhắn mới"
                data = PushOutboxService._serialize_data(payload.get("data") or {})

                devices = device_repo.list_active_devices(job.user_id)
                if not devices:
                    outbox_repo.update_status(
                        job.id,
                        status=NotificationOutboxStatus.CANCELLED.value,
                        sent_at=datetime.utcnow(),
                        error="No active devices",
                    )
                    db.commit()
                    continue

                success_count = 0
                errors: List[str] = []
                for device in devices:
                    try:
                        msg = messaging.Message(
                            token=device.push_token,
                            notification=messaging.Notification(title=title, body=body),
                            data=data,
                        )
                        messaging.send(msg, app=get_firebase_app())
                        success_count += 1
                    except Exception as exc:
                        errors.append(str(exc))
                        if PushOutboxService._is_invalid_token_error(exc):
                            UserDeviceRepositoryImpl(db).deactivate_by_token(
                                device.push_token,
                                commit=False,
                            )

                if success_count > 0:
                    outbox_repo.update_status(
                        job.id,
                        status=NotificationOutboxStatus.SENT.value,
                        sent_at=datetime.utcnow(),
                        error=None,
                    )
                    db.commit()
                    continue

                PushOutboxService._retry_or_cancel(job, errors[0] if errors else "Push send failed")
                outbox_repo.update_status(
                    job.id,
                    status=job.status,
                    error=job.last_error,
                    next_retry_at=job.next_retry_at,
                    retry_count=job.retry_count,
                )
                db.commit()
            except Exception as exc:
                db.rollback()
                failed_entity = outbox_repo.get_by_id(job.id)
                if failed_entity:
                    PushOutboxService._retry_or_cancel(failed_entity, str(exc))
                    outbox_repo.update_status(
                        failed_entity.id,
                        status=failed_entity.status,
                        error=failed_entity.last_error,
                        next_retry_at=failed_entity.next_retry_at,
                        retry_count=failed_entity.retry_count,
                    )
                    db.commit()

        return processed
