from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.analysis_result import AnalysisResult
from app.models.analysis_session import AnalysisSession
from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove
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
        best_expert_file=result_data.best_expert_file,
        best_novice_frame=result_data.best_novice_frame,
        best_expert_frame=result_data.best_expert_frame,
        worst_novice_frame=result_data.worst_novice_frame,
        worst_expert_frame=result_data.worst_expert_frame,
        problematic_joints_text=result_data.problematic_joints_text,
        best_heatmap_url=result_data.best_heatmap_url,
        worst_heatmap_url=result_data.worst_heatmap_url,
    )

    db.add(new_result)
    session.status = "completed"

    db.commit()
    db.refresh(new_result)

    predicted_style_name = None
    predicted_move_name = None

    if session.predicted_style_id is not None:
        style_obj = (
            db.query(DanceStyle)
            .filter(DanceStyle.id == session.predicted_style_id)
            .first()
        )
        if style_obj:
            predicted_style_name = style_obj.name

    if session.predicted_move_id is not None:
        move_obj = (
            db.query(DanceMove)
            .filter(DanceMove.id == session.predicted_move_id)
            .first()
        )
        if move_obj:
            predicted_move_name = move_obj.name

    return AnalysisResultResponse(
        id=new_result.id,
        analysis_session_id=new_result.analysis_session_id,
        overall_score=new_result.overall_score,
        arms_score=new_result.arms_score,
        legs_score=new_result.legs_score,
        feedback_summary=new_result.feedback_summary,
        strengths_text=new_result.strengths_text,
        improvements_text=new_result.improvements_text,
        predicted_style_name=predicted_style_name,
        predicted_move_name=predicted_move_name,
        best_expert_file=new_result.best_expert_file,
        best_novice_frame=new_result.best_novice_frame,
        best_expert_frame=new_result.best_expert_frame,
        worst_novice_frame=new_result.worst_novice_frame,
        worst_expert_frame=new_result.worst_expert_frame,
        problematic_joints_text=new_result.problematic_joints_text,
        best_heatmap_url=new_result.best_heatmap_url,
        worst_heatmap_url=new_result.worst_heatmap_url,
        created_at=new_result.created_at,
    )


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

    predicted_style_name = None
    predicted_move_name = None

    if session.predicted_style_id is not None:
        style_obj = (
            db.query(DanceStyle)
            .filter(DanceStyle.id == session.predicted_style_id)
            .first()
        )
        if style_obj:
            predicted_style_name = style_obj.name

    if session.predicted_move_id is not None:
        move_obj = (
            db.query(DanceMove)
            .filter(DanceMove.id == session.predicted_move_id)
            .first()
        )
        if move_obj:
            predicted_move_name = move_obj.name

    return AnalysisResultResponse(
        id=result.id,
        analysis_session_id=result.analysis_session_id,
        overall_score=result.overall_score,
        arms_score=result.arms_score,
        legs_score=result.legs_score,
        feedback_summary=result.feedback_summary,
        strengths_text=result.strengths_text,
        improvements_text=result.improvements_text,
        predicted_style_name=predicted_style_name,
        predicted_move_name=predicted_move_name,
        best_expert_file=result.best_expert_file,
        best_novice_frame=result.best_novice_frame,
        best_expert_frame=result.best_expert_frame,
        worst_novice_frame=result.worst_novice_frame,
        worst_expert_frame=result.worst_expert_frame,
        problematic_joints_text=result.problematic_joints_text,
        best_heatmap_url=result.best_heatmap_url,
        worst_heatmap_url=result.worst_heatmap_url,
        created_at=result.created_at,
    )