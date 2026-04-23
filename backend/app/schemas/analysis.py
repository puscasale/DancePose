from pydantic import BaseModel
from datetime import datetime


class AnalysisSessionCreate(BaseModel):
    mode: str
    source_type: str
    input_video_path: str
    selected_style_id: int | None = None
    selected_move_id: int | None = None


class AnalysisSessionResponse(BaseModel):
    id: int
    user_id: int
    mode: str
    source_type: str
    status: str
    input_video_path: str
    selected_style_id: int | None = None
    selected_move_id: int | None = None
    predicted_style_id: int | None = None
    predicted_move_id: int | None = None
    created_at: datetime
    completed_at: datetime | None = None

    class Config:
        from_attributes = True