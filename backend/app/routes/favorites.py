from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User
from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove
from app.models.favorite_style import FavoriteStyle
from app.models.favorite_move import FavoriteMove
from app.routes.dependencies import get_current_user
from app.schemas.favorite import (
    FavoritesResponse,
    FavoriteStyleItem,
    FavoriteMoveItem,
    SimpleMessageResponse,
)

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("/", response_model=FavoritesResponse)
def get_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    favorite_styles = (
        db.query(FavoriteStyle, DanceStyle)
        .join(DanceStyle, FavoriteStyle.style_id == DanceStyle.id)
        .filter(FavoriteStyle.user_id == current_user.id)
        .order_by(DanceStyle.name.asc())
        .all()
    )

    favorite_moves = (
        db.query(DanceMove, DanceStyle)
        .join(FavoriteMove, FavoriteMove.move_id == DanceMove.id)
        .outerjoin(DanceStyle, DanceMove.style_id == DanceStyle.id)
        .filter(FavoriteMove.user_id == current_user.id)
        .order_by(DanceMove.name.asc())
        .all()
    )

    return FavoritesResponse(
        styles=[
            FavoriteStyleItem(
                style_id=style.id,
                style_name=style.name,
            )
            for _, style in favorite_styles
        ],
        moves=[
            FavoriteMoveItem(
                move_id=move.id,
                move_name=move.name,
                style_id=style.id if style else None,
                style_name=style.name if style else None,
            )
            for move, style in favorite_moves
        ],
    )


@router.post("/styles/{style_id}", response_model=SimpleMessageResponse)
def add_favorite_style(
    style_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    style = db.query(DanceStyle).filter(DanceStyle.id == style_id).first()
    if not style:
        raise HTTPException(status_code=404, detail="Style not found")

    existing = (
        db.query(FavoriteStyle)
        .filter(
            FavoriteStyle.user_id == current_user.id,
            FavoriteStyle.style_id == style_id,
        )
        .first()
    )

    if existing:
        return SimpleMessageResponse(message="Style already in favorites")

    favorite = FavoriteStyle(user_id=current_user.id, style_id=style_id)
    db.add(favorite)
    db.commit()

    return SimpleMessageResponse(message="Style added to favorites")


@router.delete("/styles/{style_id}", response_model=SimpleMessageResponse)
def remove_favorite_style(
    style_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    favorite = (
        db.query(FavoriteStyle)
        .filter(
            FavoriteStyle.user_id == current_user.id,
            FavoriteStyle.style_id == style_id,
        )
        .first()
    )

    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite style not found")

    db.delete(favorite)
    db.commit()

    return SimpleMessageResponse(message="Style removed from favorites")


@router.post("/moves/{move_id}", response_model=SimpleMessageResponse)
def add_favorite_move(
    move_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    move = db.query(DanceMove).filter(DanceMove.id == move_id).first()
    if not move:
        raise HTTPException(status_code=404, detail="Move not found")

    existing = (
        db.query(FavoriteMove)
        .filter(
            FavoriteMove.user_id == current_user.id,
            FavoriteMove.move_id == move_id,
        )
        .first()
    )

    if existing:
        return SimpleMessageResponse(message="Move already in favorites")

    favorite = FavoriteMove(user_id=current_user.id, move_id=move_id)
    db.add(favorite)
    db.commit()

    return SimpleMessageResponse(message="Move added to favorites")


@router.delete("/moves/{move_id}", response_model=SimpleMessageResponse)
def remove_favorite_move(
    move_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    favorite = (
        db.query(FavoriteMove)
        .filter(
            FavoriteMove.user_id == current_user.id,
            FavoriteMove.move_id == move_id,
        )
        .first()
    )

    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite move not found")

    db.delete(favorite)
    db.commit()

    return SimpleMessageResponse(message="Move removed from favorites")