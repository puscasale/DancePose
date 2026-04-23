from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class AnalysisSession(Base):
    __tablename__ = "analysis_sessions"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    mode = Column(String, nullable=False)  # learning / auto_detect
    source_type = Column(String, nullable=False)  # gallery / camera
    status = Column(String, nullable=False, default="uploaded")  # uploaded / processing / completed / failed

    input_video_path = Column(String, nullable=False)

    selected_style_id = Column(Integer, ForeignKey("dance_styles.id"), nullable=True)
    selected_move_id = Column(Integer, ForeignKey("dance_moves.id"), nullable=True)

    predicted_style_id = Column(Integer, ForeignKey("dance_styles.id"), nullable=True)
    predicted_move_id = Column(Integer, ForeignKey("dance_moves.id"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User")