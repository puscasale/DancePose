import os
import shutil
from uuid import uuid4
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.analysis_session import AnalysisSession
from app.models.analysis_result import AnalysisResult
from app.schemas.analysis import AnalysisSessionCreate, AnalysisSessionResponse
from app.routes.dependencies import get_current_user
from app.models.user import User
from app.ai.pipeline import run_preprocessing_pipeline
from app.ai.scoring import compute_overall_ai_score, compute_body_part_scores
from app.ai.heatmap import generate_session_heatmaps
from app.ai.llm_feedback import generate_llm_feedback
from app.ai.storage import upload_file_to_bucket
from app.core.config import settings
from pathlib import Path
from app.ai.classify import classify_dance, resolve_predicted_ids

router = APIRouter(prefix="/analysis", tags=["analysis"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
def _safe_delete_file(path: str | None):
    if not path:
        return

    try:
        file_path = Path(path)
        if file_path.exists() and file_path.is_file():
            file_path.unlink()
            print(f"[CLEANUP] deleted local file: {file_path}")
    except Exception as e:
        print(f"[CLEANUP WARNING] could not delete {path}: {e}")


def _create_result_for_session(
    db: Session,
    session: AnalysisSession,
    overall_score: float,
    arms_score: float,
    legs_score: float,
    feedback_summary: str | None = None,
    strengths_text: str | None = None,
    improvements_text: str | None = None,
    best_expert_file: str | None = None,
    best_novice_frame: int | None = None,
    best_expert_frame: int | None = None,
    worst_novice_frame: int | None = None,
    worst_expert_frame: int | None = None,
    problematic_joints_text: str | None = None,
    best_heatmap_url: str | None = None,
    worst_heatmap_url: str | None = None,
) -> AnalysisResult:
    existing_result = (
        db.query(AnalysisResult)
        .filter(AnalysisResult.analysis_session_id == session.id)
        .first()
    )
    if existing_result:
        return existing_result

    result = AnalysisResult(
        analysis_session_id=session.id,
        overall_score=overall_score,
        arms_score=arms_score,
        legs_score=legs_score,
        feedback_summary=feedback_summary,
        strengths_text=strengths_text,
        improvements_text=improvements_text,
        best_expert_file=best_expert_file,
        best_novice_frame=best_novice_frame,
        best_expert_frame=best_expert_frame,
        worst_novice_frame=worst_novice_frame,
        worst_expert_frame=worst_expert_frame,
        problematic_joints_text=problematic_joints_text,
        best_heatmap_url=best_heatmap_url,
        worst_heatmap_url=worst_heatmap_url,
    )

    session.status = "completed"
    session.completed_at = datetime.now(timezone.utc)

    db.add(result)
    db.commit()
    db.refresh(result)

    return result


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

    return new_session


@router.post("/upload", response_model=AnalysisSessionResponse, status_code=status.HTTP_201_CREATED)
def upload_analysis_video(
    request: Request,
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
        raise HTTPException(status_code=400, detail="Unsupported video format")

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
    preprocessing_info = None
    heatmap_data = None

    try:
        preprocessing_info = run_preprocessing_pipeline(
            video_path=saved_path,
            session_id=new_session.id,
        )
        print("[STEP] preprocessing done")

        classification = classify_dance(
            skeleton_path=preprocessing_info["model_input_path"],
            video_feature_path=preprocessing_info["video_feature_path"],
            )
        print("[STEP] classification done")

        predicted_style_id, predicted_move_id = resolve_predicted_ids(
            db,
            style_name=classification["style_name"],
            move_name=classification["move_name"],
        )

        new_session.predicted_style_id = predicted_style_id
        new_session.predicted_move_id = predicted_move_id
        db.commit()
        db.refresh(new_session)

        selected_style_name = None
        selected_move_name = None

        if new_session.selected_style_id is not None:
            from app.models.dance_style import DanceStyle
            style_obj = (
                db.query(DanceStyle)
                .filter(DanceStyle.id == new_session.selected_style_id)
                .first()
            )
            if style_obj:
                selected_style_name = style_obj.name

        if new_session.selected_move_id is not None:
            from app.models.dance_move import DanceMove
            move_obj = (
                db.query(DanceMove)
                .filter(DanceMove.id == new_session.selected_move_id)
                .first()
            )
            if move_obj:
                selected_move_name = move_obj.name

        overall_data = compute_overall_ai_score(
            novice_model_input_path=preprocessing_info["model_input_path"],
            novice_video_feature_path=preprocessing_info["video_feature_path"],
            mode=new_session.mode,
            predicted_label=classification["predicted_label"],
            selected_style_name=selected_style_name,
            selected_move_name=selected_move_name,
        )
        print("[STEP] overall scoring done")

        part_scores = compute_body_part_scores(
            novice_normalized_full_path=preprocessing_info["normalized_full_path"],
            expert_normalized_full_path=overall_data["best_expert_path"],
        )
        print("[STEP] body part scoring done")

        overall_ai_score_raw = overall_data["overall_ai_score"]
        arms_score_raw = part_scores["arms_score_raw"]
        legs_score_raw = part_scores["legs_score_raw"]

        overall_final_raw = (
            0.5 * overall_ai_score_raw +
            0.25 * arms_score_raw +
            0.25 * legs_score_raw
        )

        overall_score = overall_final_raw / 10.0
        arms_score = arms_score_raw / 10.0
        legs_score = legs_score_raw / 10.0

        heatmap_data = generate_session_heatmaps(
            novice_skeleton_path=preprocessing_info["normalized_full_path"],
            expert_skeleton_path=overall_data["best_expert_path"],
            best_novice_frame=part_scores["best_novice_frame"],
            best_expert_frame=part_scores["best_expert_frame"],
            worst_novice_frame=part_scores["worst_novice_frame"],
            worst_expert_frame=part_scores["worst_expert_frame"],
            session_id=new_session.id,
        )
        print("[STEP] heatmaps generated")


        video_public_url = upload_file_to_bucket(
            local_file_path=saved_path,
            bucket_name=settings.SUPABASE_VIDEOS_BUCKET,
            remote_path=f"user_{current_user.id}/session_{new_session.id}/original{ext}",
        )
        print("[STEP] video uploaded to supabase")

        best_heatmap_url = upload_file_to_bucket(
            local_file_path=heatmap_data["best_heatmap_path"],
            bucket_name=settings.SUPABASE_HEATMAPS_BUCKET,
            remote_path=f"user_{current_user.id}/session_{new_session.id}/best_heatmap.png",
        )
        print("[STEP] best heatmap uploaded")

        worst_heatmap_url = upload_file_to_bucket(
            local_file_path=heatmap_data["worst_heatmap_path"],
            bucket_name=settings.SUPABASE_HEATMAPS_BUCKET,
            remote_path=f"user_{current_user.id}/session_{new_session.id}/worst_heatmap.png",
        )
        print("[STEP] worst heatmap uploaded")

        new_session.input_video_path = video_public_url
        db.commit()
        db.refresh(new_session)

        best_time_sec = part_scores["best_novice_frame"] / 30.0
        worst_time_sec = part_scores["worst_novice_frame"] / 30.0

        llm_feedback = generate_llm_feedback(
            predicted_label=classification["predicted_label"],
            overall_score=overall_score,
            arms_score=arms_score,
            legs_score=legs_score,
            best_novice_second=best_time_sec,
            worst_novice_second=worst_time_sec,
            problematic_joints_text=heatmap_data["problematic_joints_text"],
        )
        print("[STEP] llm feedback generated")

        _create_result_for_session(
            db=db,
            session=new_session,
            overall_score=overall_score,
            arms_score=arms_score,
            legs_score=legs_score,
            feedback_summary=llm_feedback["summary"],
            strengths_text=llm_feedback["strengths"],
            improvements_text=llm_feedback["improvements"],
            best_expert_file=overall_data["best_expert_file"],
            best_novice_frame=part_scores["best_novice_frame"],
            best_expert_frame=part_scores["best_expert_frame"],
            worst_novice_frame=part_scores["worst_novice_frame"],
            worst_expert_frame=part_scores["worst_expert_frame"],
            problematic_joints_text=heatmap_data["problematic_joints_text"],
            best_heatmap_url=best_heatmap_url,
            worst_heatmap_url=worst_heatmap_url,
        )
        db.refresh(new_session)

        return new_session

    except Exception as e:
        import traceback
        traceback.print_exc()

        new_session.status = "failed"
        new_session.completed_at = datetime.now(timezone.utc)
        db.commit()

        raise HTTPException(
            status_code=500,
            detail=f"Analysis pipeline failed: {str(e)}",
        )
    finally:
        _safe_delete_file(saved_path)

        if preprocessing_info:
            _safe_delete_file(preprocessing_info.get("model_input_path"))
            _safe_delete_file(preprocessing_info.get("video_feature_path"))
            _safe_delete_file(preprocessing_info.get("normalized_full_path"))

        if heatmap_data:
            _safe_delete_file(heatmap_data.get("best_heatmap_path"))
            _safe_delete_file(heatmap_data.get("worst_heatmap_path"))


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