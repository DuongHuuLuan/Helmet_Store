from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base

class Cart(Base):
    __tablename__ = "carts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)


    user = relationship("User", back_populates="cart")
    cart_details = relationship("CartDetail", back_populates="cart", cascade="all, delete-orphan")