from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, func
from sqlalchemy.orm import relationship
from app.infrastructure.database.base import Base
import enum

class Distributor(Base):
    __tablename__ = "distributors"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100))
    address = Column(String(255))

    