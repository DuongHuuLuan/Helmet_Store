from abc import ABC, abstractmethod
from datetime import datetime
from typing import Optional

from app.domain.entities.notification_outbox_entity import NotificationOutboxEntity


class NotificationOutboxRepository(ABC):
    @abstractmethod
    def get_by_dedupe_key(self, dedupe_key: str) -> Optional[NotificationOutboxEntity]: ...

    @abstractmethod
    def get_by_id(self, id: int) -> Optional[NotificationOutboxEntity]: ...

    @abstractmethod
    def create(self, data: dict) -> NotificationOutboxEntity: ...

    @abstractmethod
    def list_due_jobs(self, limit: int, now: Optional[datetime] = None) -> list[NotificationOutboxEntity]: ...

    @abstractmethod
    def update_status(self, id: int, status: str,
                      error: Optional[str] = None,
                      next_retry_at: Optional[datetime] = None,
                      sent_at: Optional[datetime] = None,
                      retry_count: Optional[int] = None) -> Optional[NotificationOutboxEntity]: ...
