from pydantic import BaseModel


class DanceStyleBase(BaseModel):
    name: str
    description: str | None = None


class DanceStyleCreate(DanceStyleBase):
    pass


class DanceStyleResponse(DanceStyleBase):
    id: int

    class Config:
        from_attributes = True