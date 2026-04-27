from sqlalchemy import Column, Integer, Float, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class AnalysisResult(Base):
    __tablename__ = "analysis_results"

    id = Column(Integer, primary_key=True, index=True)

    analysis_session_id = Column(
        Integer,
        ForeignKey("analysis_sessions.id"),
        nullable=False,
        unique=True,
    )

    overall_score = Column(Float, nullable=True)
    arms_score = Column(Float, nullable=True)
    legs_score = Column(Float, nullable=True)

    feedback_summary = Column(Text, nullable=True)
    strengths_text = Column(Text, nullable=True)
    improvements_text = Column(Text, nullable=True)

    best_expert_file = Column(Text, nullable=True)

    best_novice_frame = Column(Integer, nullable=True)
    best_expert_frame = Column(Integer, nullable=True)
    worst_novice_frame = Column(Integer, nullable=True)
    worst_expert_frame = Column(Integer, nullable=True)

    problematic_joints_text = Column(Text, nullable=True)
    best_heatmap_url = Column(Text, nullable=True)
    worst_heatmap_url = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    session = relationship("AnalysisSession")