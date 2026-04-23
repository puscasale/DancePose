from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.dance_style import DanceStyle
from app.schemas.dance_style import DanceStyleResponse

router = APIRouter(prefix="/styles", tags=["styles"])


@router.get("/", response_model=list[DanceStyleResponse])
def get_styles(db: Session = Depends(get_db)):
    return db.query(DanceStyle).order_by(DanceStyle.name.asc()).all()