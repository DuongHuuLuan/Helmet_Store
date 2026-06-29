from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL, echo=True)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


def get_db():
    """
    Hàm  generator để tạo và đóng Session tự động.add()
    Sẽ được dùng với Depends(get_db) trong các API
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()