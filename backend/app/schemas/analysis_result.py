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
    best_expert_file: str | None = None
    best_novice_frame: int | None = None
    best_expert_frame: int | None = None
    worst_novice_frame: int | None = None
    worst_expert_frame: int | None = None
    best_novice_second: float | None = None
    worst_novice_second: float | None = None
    best_heatmap_url: str | None = None
    worst_heatmap_url: str | None = None
    problematic_joints_text: str | None = None


class AnalysisResultResponse(BaseModel):
    id: int
    analysis_session_id: int
    overall_score: float | None = None
    arms_score: float | None = None
    legs_score: float | None = None

    feedback_summary: str | None = None
    strengths_text: str | None = None
    improvements_text: str | None = None

    predicted_style_name: str | None = None
    predicted_move_name: str | None = None

    best_expert_file: str | None = None
    best_novice_frame: int | None = None
    best_expert_frame: int | None = None
    worst_novice_frame: int | None = None
    worst_expert_frame: int | None = None

    problematic_joints_text: str | None = None
    best_heatmap_url: str | None = None
    worst_heatmap_url: str | None = None

    created_at: datetime

    class Config:
        from_attributes = True