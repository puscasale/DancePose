from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.dance_move import DanceMove
from app.models.dance_style import DanceStyle
from app.schemas.dance_move import DanceMoveResponse

router = APIRouter(prefix="/moves", tags=["moves"])


@router.get("/", response_model=list[DanceMoveResponse])
def get_all_moves(db: Session = Depends(get_db)):
    return db.query(DanceMove).order_by(DanceMove.name.asc()).all()


@router.get("/style/{style_id}", response_model=list[DanceMoveResponse])
def get_moves_by_style(style_id: int, db: Session = Depends(get_db)):
    style = db.query(DanceStyle).filter(DanceStyle.id == style_id).first()
    if not style:
        raise HTTPException(status_code=404, detail="Style not found")

    return (
        db.query(DanceMove)
        .filter(DanceMove.style_id == style_id)
        .order_by(DanceMove.name.asc())
        .all()
    )