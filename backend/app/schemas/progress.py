from datetime import datetime
from pydantic import BaseModel


class ProgressHistoryItem(BaseModel):
    session_id: int
    mode: str
    source_type: str
    status: str
    created_at: datetime
    completed_at: datetime | None = None

    style_name: str | None = None
    move_name: str | None = None

    overall_score: float | None = None
    arms_score: float | None = None
    legs_score: float | None = None

    class Config:
        from_attributes = True

class StyleAverageItem(BaseModel):
    style_name: str
    average_score: float


class ProgressStatsResponse(BaseModel):
    best_score_ever: float | None = None
    total_sessions: int
    most_practiced_move: str | None = None
    last_activity: datetime | None = None
    average_by_style: list[StyleAverageItem]