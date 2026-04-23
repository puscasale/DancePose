from pydantic import BaseModel


class DanceMoveBase(BaseModel):
    name: str
    description: str | None = None
    difficulty: str | None = None
    tutorial_video_path: str | None = None


class DanceMoveCreate(DanceMoveBase):
    style_id: int


class DanceMoveResponse(DanceMoveBase):
    id: int
    style_id: int

    class Config:
        from_attributes = True