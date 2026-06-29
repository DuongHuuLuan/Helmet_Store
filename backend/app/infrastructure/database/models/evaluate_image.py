from sqlalchemy import Column, ForeignKey, Integer, String, DateTime, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base


class EvaluateImage(Base):
    __tablename__ = "evaluate_images"

    id = Column(Integer, primary_key= True, index=True)
    evaluate_id = Column(Integer, ForeignKey("evaluates.id", ondelete="CASCADE"), nullable=False, index=True)
    image_url = Column(String(255), nullable=False)
    public_id = Column(String(255), nullable=True)
    sort_order = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


    evaluate = relationship("Evaluate", back_populates="images")
