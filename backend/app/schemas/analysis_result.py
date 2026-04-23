from pydantic import BaseModel
from datetime import datetime


class AnalysisResultCreate(BaseModel):
    analysis_session_id: int
    overall_score: float | None = None
    arms_score: float | None = None
    legs_score: float | None = None
    feedback_summary: str | None = None
    strengths_text: str | None = None
    improvements_text: str | None = None


class AnalysisResultResponse(BaseModel):
    id: int
    analysis_session_id: int
    overall_score: float | None = None
    arms_score: float | None = None
    legs_score: float | None = None
    feedback_summary: str | None = None
    strengths_text: str | None = None
    improvements_text: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True