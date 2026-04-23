from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class DanceStyle(Base):
    __tablename__ = "dance_styles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)

    moves = relationship("DanceMove", back_populates="style", cascade="all, delete")