import os
import shutil
import random
from uuid import uuid4
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.analysis_session import AnalysisSession
from app.models.analysis_result import AnalysisResult
from app.schemas.analysis import AnalysisSessionCreate, AnalysisSessionResponse
from app.routes.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/analysis", tags=["analysis"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _generate_mock_result_text(mode: str, selected_move_id: int | None) -> tuple[str, str, str]:
    if mode == "auto_detect":
        summary = (
            "The AI completed a preliminary movement analysis and generated an automatic prediction flow. "
            "Timing appears promising, but some transitions still need refinement."
        )
        strengths = (
            "Good overall rhythm, stable movement energy, and clear lower-body control in the main sequence."
        )
        improvements = (
            "Work on cleaner upper-body accents, more precise arm placement, and smoother transitions between steps."
        )
        return summary, strengths, improvements

    if selected_move_id is not None:
        summary = (
            "The uploaded performance shows a solid understanding of the selected move, with good timing and body coordination overall."
        )
        strengths = (
            "Strong rhythm, balanced foot placement, and good consistency through the main phase of the movement."
        )
        improvements = (
            "Try to improve sharpness in the upper body and make the movement finish positions cleaner and more controlled."
        )
        return summary, strengths, improvements

    return (
        "The analysis has been completed successfully.",
        "Movement flow is stable and readable.",
        "Refine timing and posture for a cleaner final execution.",
    )


def _create_mock_result_for_session(db: Session, session: AnalysisSession) -> AnalysisResult:
    existing_result = (
        db.query(AnalysisResult)
        .filter(AnalysisResult.analysis_session_id == session.id)
        .first()
    )
    if existing_result:
        return existing_result

    overall_score = round(random.uniform(7.2, 9.4), 1)
    arms_score = round(max(5.0, min(10.0, overall_score + random.uniform(-0.8, 0.6))), 1)
    legs_score = round(max(5.0, min(10.0, overall_score + random.uniform(-0.6, 0.8))), 1)

    summary, strengths, improvements = _generate_mock_result_text(
        session.mode,
        session.selected_move_id,
    )

    mock_result = AnalysisResult(
        analysis_session_id=session.id,
        overall_score=overall_score,
        arms_score=arms_score,
        legs_score=legs_score,
        feedback_summary=summary,
        strengths_text=strengths,
        improvements_text=improvements,
    )

    session.status = "completed"
    session.completed_at = datetime.now(timezone.utc)

    db.add(mock_result)
    db.commit()
    db.refresh(mock_result)

    return mock_result


@router.post("/", response_model=AnalysisSessionResponse, status_code=status.HTTP_201_CREATED)
def create_analysis_session(
    session_data: AnalysisSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    new_session = AnalysisSession(
        user_id=current_user.id,
        mode=session_data.mode,
        source_type=session_data.source_type,
        status="uploaded",
        input_video_path=session_data.input_video_path,
        selected_style_id=session_data.selected_style_id,
        selected_move_id=session_data.selected_move_id,
    )

    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    _create_mock_result_for_session(db, new_session)
    db.refresh(new_session)

    return new_session


@router.post("/upload", response_model=AnalysisSessionResponse, status_code=status.HTTP_201_CREATED)
def upload_analysis_video(
    mode: str = Form(...),
    source_type: str = Form(...),
    selected_style_id: int | None = Form(None),
    selected_move_id: int | None = Form(None),
    video: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not video.filename:
        raise HTTPException(status_code=400, detail="No video file provided")

    allowed_extensions = {".mp4", ".mov", ".avi", ".mkv"}
    _, ext = os.path.splitext(video.filename.lower())

    if ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Unsupported video format",
        )

    unique_filename = f"{uuid4().hex}{ext}"
    saved_path = os.path.join(UPLOAD_DIR, unique_filename)

    with open(saved_path, "wb") as buffer:
        shutil.copyfileobj(video.file, buffer)

    new_session = AnalysisSession(
        user_id=current_user.id,
        mode=mode,
        source_type=source_type,
        status="uploaded",
        input_video_path=saved_path,
        selected_style_id=selected_style_id,
        selected_move_id=selected_move_id,
    )

    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    _create_mock_result_for_session(db, new_session)
    db.refresh(new_session)

    return new_session


@router.get("/", response_model=list[AnalysisSessionResponse])
def get_my_analysis_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(AnalysisSession)
        .filter(AnalysisSession.user_id == current_user.id)
        .order_by(AnalysisSession.created_at.desc())
        .all()
    )


@router.get("/{session_id}", response_model=AnalysisSessionResponse)
def get_analysis_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(AnalysisSession)
        .filter(
            AnalysisSession.id == session_id,
            AnalysisSession.user_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(status_code=404, detail="Analysis session not found")

    return session