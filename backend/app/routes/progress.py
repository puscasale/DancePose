from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.analysis_session import AnalysisSession
from app.models.analysis_result import AnalysisResult
from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove
from app.models.user import User
from app.routes.dependencies import get_current_user
from app.schemas.progress import (
    ProgressHistoryItem,
    ProgressStatsResponse,
    StyleAverageItem,
)

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/history", response_model=list[ProgressHistoryItem])
def get_progress_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sessions = (
        db.query(AnalysisSession)
        .filter(AnalysisSession.user_id == current_user.id)
        .order_by(AnalysisSession.created_at.desc())
        .all()
    )

    history_items: list[ProgressHistoryItem] = []

    for session in sessions:
        result = (
            db.query(AnalysisResult)
            .filter(AnalysisResult.analysis_session_id == session.id)
            .first()
        )

        style_name = None
        move_name = None

        if session.selected_style_id is not None:
            style = (
                db.query(DanceStyle)
                .filter(DanceStyle.id == session.selected_style_id)
                .first()
            )
            if style:
                style_name = style.name

        if session.selected_move_id is not None:
            move = (
                db.query(DanceMove)
                .filter(DanceMove.id == session.selected_move_id)
                .first()
            )
            if move:
                move_name = move.name

        history_items.append(
            ProgressHistoryItem(
                session_id=session.id,
                mode=session.mode,
                source_type=session.source_type,
                status=session.status,
                created_at=session.created_at,
                completed_at=session.completed_at,
                style_name=style_name,
                move_name=move_name,
                overall_score=result.overall_score if result else None,
                arms_score=result.arms_score if result else None,
                legs_score=result.legs_score if result else None,
            )
        )

    return history_items


@router.get("/stats", response_model=ProgressStatsResponse)
def get_progress_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sessions = (
        db.query(AnalysisSession)
        .filter(AnalysisSession.user_id == current_user.id)
        .order_by(AnalysisSession.created_at.desc())
        .all()
    )

    total_sessions = len(sessions)
    last_activity = sessions[0].created_at if sessions else None

    best_score_ever = None
    style_scores: dict[str, list[float]] = {}
    move_counts: dict[str, int] = {}

    for session in sessions:
        result = (
            db.query(AnalysisResult)
            .filter(AnalysisResult.analysis_session_id == session.id)
            .first()
        )

        style_name = None
        move_name = None

        if session.selected_style_id is not None:
            style = (
                db.query(DanceStyle)
                .filter(DanceStyle.id == session.selected_style_id)
                .first()
            )
            if style:
                style_name = style.name

        if session.selected_move_id is not None:
            move = (
                db.query(DanceMove)
                .filter(DanceMove.id == session.selected_move_id)
                .first()
            )
            if move:
                move_name = move.name

        if move_name:
            move_counts[move_name] = move_counts.get(move_name, 0) + 1

        if result and result.overall_score is not None:
            if best_score_ever is None or result.overall_score > best_score_ever:
                best_score_ever = result.overall_score

            if style_name:
                style_scores.setdefault(style_name, []).append(result.overall_score)

    average_by_style = [
        StyleAverageItem(
            style_name=style_name,
            average_score=round(sum(scores) / len(scores), 2),
        )
        for style_name, scores in style_scores.items()
        if scores
    ]
    average_by_style.sort(key=lambda item: item.average_score, reverse=True)

    most_practiced_move = None
    if move_counts:
        most_practiced_move = max(move_counts, key=move_counts.get)

    return ProgressStatsResponse(
        best_score_ever=best_score_ever,
        total_sessions=total_sessions,
        most_practiced_move=most_practiced_move,
        last_activity=last_activity,
        average_by_style=average_by_style,
    )