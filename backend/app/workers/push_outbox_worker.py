import logging
import time

from app.core.config import settings
from app.infrastructure.database.session import SessionLocal
from app.application.push.outbox_service import PushOutboxService


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("push_outbox_worker")


def run_once() -> int:
    db = SessionLocal()
    try:
        return PushOutboxService.process_due_jobs(
            db=db,
            limit=settings.PUSH_OUTBOX_BATCH_SIZE,
        )
    finally:
        db.close()


def run_forever() -> None:
    poll_interval = max(1, settings.PUSH_OUTBOX_POLL_INTERVAL_SECONDS)
    logger.info("Push outbox worker started")
    while True:
        try:
            processed = run_once()
            if processed > 0:
                logger.info("Processed %s outbox jobs", processed)
            else:
                time.sleep(poll_interval)
        except Exception:
            logger.exception("Failed while processing outbox jobs")
            time.sleep(poll_interval)


if __name__ == "__main__":
    run_forever()
