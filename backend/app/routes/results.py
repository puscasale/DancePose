from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.analysis_result import AnalysisResult
from app.models.analysis_session import AnalysisSession
from app.models.user import User
from app.routes.dependencies import get_current_user
from app.schemas.analysis_result import (
    AnalysisResultCreate,
    AnalysisResultResponse,
)

router = APIRouter(prefix="/results", tags=["results"])


@router.post("/", response_model=AnalysisResultResponse, status_code=status.HTTP_201_CREATED)
def create_analysis_result(
    result_data: AnalysisResultCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(AnalysisSession)
        .filter(
            AnalysisSession.id == result_data.analysis_session_id,
            AnalysisSession.user_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(status_code=404, detail="Analysis session not found")

    existing_result = (
        db.query(AnalysisResult)
        .filter(AnalysisResult.analysis_session_id == result_data.analysis_session_id)
        .first()
    )

    if existing_result:
        raise HTTPException(
            status_code=400,
            detail="A result already exists for this session",
        )

    new_result = AnalysisResult(
        analysis_session_id=result_data.analysis_session_id,
        overall_score=result_data.overall_score,
        arms_score=result_data.arms_score,
        legs_score=result_data.legs_score,
        feedback_summary=result_data.feedback_summary,
        strengths_text=result_data.strengths_text,
        improvements_text=result_data.improvements_text,
    )

    db.add(new_result)

    session.status = "completed"

    db.commit()
    db.refresh(new_result)

    return new_result


@router.get("/session/{session_id}", response_model=AnalysisResultResponse)
def get_result_for_session(
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

    result = (
        db.query(AnalysisResult)
        .filter(AnalysisResult.analysis_session_id == session_id)
        .first()
    )

    if not result:
        raise HTTPException(status_code=404, detail="Result not found")

    return result