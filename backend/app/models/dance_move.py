from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class DanceMove(Base):
    __tablename__ = "dance_moves"

    id = Column(Integer, primary_key=True, index=True)
    style_id = Column(Integer, ForeignKey("dance_styles.id"), nullable=False)
    name = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=True)
    difficulty = Column(String, nullable=True)
    tutorial_video_path = Column(String, nullable=True)

    style = relationship("DanceStyle", back_populates="moves")