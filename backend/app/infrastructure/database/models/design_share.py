from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.infrastructure.database.base import Base


class DesignShare(Base):
    __tablename__ = "design_shares"

    id = Column(Integer, primary_key=True, index=True)
    design_id = Column(
        Integer,
        ForeignKey("designs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    share_token = Column(String(255), nullable=False, unique=True, index=True)
    public_url = Column(String(500), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)

    design = relationship("Design", back_populates="shares")
