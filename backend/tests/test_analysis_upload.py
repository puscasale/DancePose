from io import BytesIO
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi import HTTPException, UploadFile

from app.core.database import SessionLocal
from app.models.analysis_result import AnalysisResult
from app.models.analysis_session import AnalysisSession
from app.routes.analysis import (
    _create_result_for_session,
    _safe_delete_file,
    upload_analysis_video,
)


def _mock_successful_pipeline(
    mock_preprocessing,
    mock_classify,
    mock_resolve_ids,
    mock_overall,
    mock_parts,
    mock_heatmaps,
    mock_upload,
    mock_feedback,
    tmp_path,
):
    fake_model_input = tmp_path / "model_input.npy"
    fake_video_features = tmp_path / "video_features.npy"
    fake_normalized = tmp_path / "normalized.npy"
    fake_best_heatmap = tmp_path / "best_heatmap.png"
    fake_worst_heatmap = tmp_path / "worst_heatmap.png"
    fake_expert = tmp_path / "expert.npy"

    fake_model_input.write_bytes(b"model")
    fake_video_features.write_bytes(b"features")
    fake_normalized.write_bytes(b"normalized")
    fake_best_heatmap.write_bytes(b"best")
    fake_worst_heatmap.write_bytes(b"worst")
    fake_expert.write_bytes(b"expert")

    mock_preprocessing.return_value = {
        "model_input_path": str(fake_model_input),
        "video_feature_path": str(fake_video_features),
        "normalized_full_path": str(fake_normalized),
    }

    mock_classify.return_value = {
        "style_name": "House",
        "move_name": "Basic Step",
        "predicted_label": "House Basic Step",
    }

    mock_resolve_ids.return_value = (1, 1)

    mock_overall.return_value = {
        "overall_ai_score": 80.0,
        "best_expert_path": str(fake_expert),
        "best_expert_file": "expert.npy",
    }

    mock_parts.return_value = {
        "arms_score_raw": 70.0,
        "legs_score_raw": 90.0,
        "best_novice_frame": 30,
        "best_expert_frame": 28,
        "worst_novice_frame": 90,
        "worst_expert_frame": 88,
    }

    mock_heatmaps.return_value = {
        "best_heatmap_path": str(fake_best_heatmap),
        "worst_heatmap_path": str(fake_worst_heatmap),
        "problematic_joints_text": "left wrist, right elbow",
    }

    mock_upload.side_effect = [
        "https://supabase.test/video.mp4",
        "https://supabase.test/best_heatmap.png",
        "https://supabase.test/worst_heatmap.png",
    ]

    mock_feedback.return_value = {
        "summary": "Good overall execution.",
        "strengths": "Good leg control.",
        "improvements": "Improve arm stability.",
    }


def _upload_video_with_mocked_pipeline(client, tmp_path):
    fake_video = tmp_path / "video.mp4"
    fake_video.write_bytes(b"fake video content")

    with patch("app.routes.analysis.run_preprocessing_pipeline") as mock_preprocessing, \
         patch("app.routes.analysis.classify_dance") as mock_classify, \
         patch("app.routes.analysis.resolve_predicted_ids") as mock_resolve_ids, \
         patch("app.routes.analysis.compute_overall_ai_score") as mock_overall, \
         patch("app.routes.analysis.compute_body_part_scores") as mock_parts, \
         patch("app.routes.analysis.generate_session_heatmaps") as mock_heatmaps, \
         patch("app.routes.analysis.upload_file_to_bucket") as mock_upload, \
         patch("app.routes.analysis.generate_llm_feedback") as mock_feedback:

        _mock_successful_pipeline(
            mock_preprocessing=mock_preprocessing,
            mock_classify=mock_classify,
            mock_resolve_ids=mock_resolve_ids,
            mock_overall=mock_overall,
            mock_parts=mock_parts,
            mock_heatmaps=mock_heatmaps,
            mock_upload=mock_upload,
            mock_feedback=mock_feedback,
            tmp_path=tmp_path,
        )

        with open(fake_video, "rb") as file:
            response = client.post(
                "/analysis/upload",
                data={
                    "mode": "auto",
                    "source_type": "gallery",
                },
                files={
                    "video": ("video.mp4", file, "video/mp4"),
                },
            )

    return response


def test_upload_analysis_video_success(client, tmp_path):
    fake_video = tmp_path / "video.mp4"
    fake_video.write_bytes(b"fake video content")

    with patch("app.routes.analysis.run_preprocessing_pipeline") as mock_preprocessing, \
         patch("app.routes.analysis.classify_dance") as mock_classify, \
         patch("app.routes.analysis.resolve_predicted_ids") as mock_resolve_ids, \
         patch("app.routes.analysis.compute_overall_ai_score") as mock_overall, \
         patch("app.routes.analysis.compute_body_part_scores") as mock_parts, \
         patch("app.routes.analysis.generate_session_heatmaps") as mock_heatmaps, \
         patch("app.routes.analysis.upload_file_to_bucket") as mock_upload, \
         patch("app.routes.analysis.generate_llm_feedback") as mock_feedback:

        _mock_successful_pipeline(
            mock_preprocessing=mock_preprocessing,
            mock_classify=mock_classify,
            mock_resolve_ids=mock_resolve_ids,
            mock_overall=mock_overall,
            mock_parts=mock_parts,
            mock_heatmaps=mock_heatmaps,
            mock_upload=mock_upload,
            mock_feedback=mock_feedback,
            tmp_path=tmp_path,
        )

        with open(fake_video, "rb") as file:
            response = client.post(
                "/analysis/upload",
                data={
                    "mode": "auto",
                    "source_type": "gallery",
                },
                files={
                    "video": ("video.mp4", file, "video/mp4"),
                },
            )

    assert response.status_code == 201

    data = response.json()

    assert data["user_id"] == 1
    assert data["mode"] == "auto"
    assert data["source_type"] == "gallery"
    assert data["status"] == "completed"
    assert data["input_video_path"] == "https://supabase.test/video.mp4"
    assert data["predicted_style_id"] == 1
    assert data["predicted_move_id"] == 1

    mock_preprocessing.assert_called_once()
    mock_classify.assert_called_once()
    mock_resolve_ids.assert_called_once()
    mock_overall.assert_called_once()
    mock_parts.assert_called_once()
    mock_heatmaps.assert_called_once()
    assert mock_upload.call_count == 3
    mock_feedback.assert_called_once()


def test_upload_analysis_video_saves_result_in_database(client, tmp_path):
    response = _upload_video_with_mocked_pipeline(client, tmp_path)

    assert response.status_code == 201

    data = response.json()
    session_id = data["id"]

    db = SessionLocal()

    try:
        result = (
            db.query(AnalysisResult)
            .filter(AnalysisResult.analysis_session_id == session_id)
            .first()
        )

        assert result is not None
        assert result.overall_score == 8.0
        assert result.arms_score == 7.0
        assert result.legs_score == 9.0
        assert result.feedback_summary == "Good overall execution."
        assert result.strengths_text == "Good leg control."
        assert result.improvements_text == "Improve arm stability."
        assert result.best_heatmap_url == "https://supabase.test/best_heatmap.png"
        assert result.worst_heatmap_url == "https://supabase.test/worst_heatmap.png"

    finally:
        db.close()


def test_get_my_analysis_sessions_returns_uploaded_session(client, tmp_path):
    upload_response = _upload_video_with_mocked_pipeline(client, tmp_path)

    assert upload_response.status_code == 201

    response = client.get("/analysis/")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1

    latest_session = data[0]

    assert latest_session["user_id"] == 1
    assert latest_session["status"] == "completed"


def test_get_analysis_session_by_id_returns_session(client, tmp_path):
    upload_response = _upload_video_with_mocked_pipeline(client, tmp_path)

    assert upload_response.status_code == 201

    session_id = upload_response.json()["id"]

    response = client.get(f"/analysis/{session_id}")

    assert response.status_code == 200

    data = response.json()

    assert data["id"] == session_id
    assert data["user_id"] == 1
    assert data["status"] == "completed"
    assert data["input_video_path"] == "https://supabase.test/video.mp4"


def test_get_analysis_session_returns_404_for_missing_session(client):
    response = client.get("/analysis/999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Analysis session not found"


def test_upload_analysis_video_rejects_invalid_extension(client, tmp_path):
    fake_file = tmp_path / "video.txt"
    fake_file.write_text("not a video")

    with open(fake_file, "rb") as file:
        response = client.post(
            "/analysis/upload",
            data={
                "mode": "auto",
                "source_type": "gallery",
            },
            files={
                "video": ("video.txt", file, "text/plain"),
            },
        )

    assert response.status_code == 400
    assert response.json()["detail"] == "Unsupported video format"


def test_upload_analysis_video_marks_session_failed_when_pipeline_crashes(client, tmp_path):
    fake_video = tmp_path / "video.mp4"
    fake_video.write_bytes(b"fake video content")

    with patch("app.routes.analysis.run_preprocessing_pipeline") as mock_preprocessing:
        mock_preprocessing.side_effect = RuntimeError("Preprocessing crashed")

        with open(fake_video, "rb") as file:
            response = client.post(
                "/analysis/upload",
                data={
                    "mode": "auto",
                    "source_type": "gallery",
                },
                files={
                    "video": ("video.mp4", file, "video/mp4"),
                },
            )

    assert response.status_code == 500
    assert "Analysis pipeline failed" in response.json()["detail"]

    db = SessionLocal()

    try:
        failed_session = (
            db.query(AnalysisSession)
            .filter(AnalysisSession.status == "failed")
            .order_by(AnalysisSession.id.desc())
            .first()
        )

        assert failed_session is not None
        assert failed_session.user_id == 1
        assert failed_session.completed_at is not None

    finally:
        db.close()


def test_create_analysis_session_endpoint(client):
    response = client.post(
        "/analysis/",
        json={
            "mode": "learn",
            "source_type": "gallery",
            "input_video_path": "local/video.mp4",
            "selected_style_id": 1,
            "selected_move_id": 1,
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == 1
    assert data["mode"] == "learn"
    assert data["source_type"] == "gallery"
    assert data["status"] == "uploaded"
    assert data["input_video_path"] == "local/video.mp4"
    assert data["selected_style_id"] == 1
    assert data["selected_move_id"] == 1


def test_upload_analysis_video_rejects_missing_filename_direct_call():
    video = UploadFile(
        filename="",
        file=BytesIO(b"fake video content"),
    )

    with pytest.raises(HTTPException) as exc_info:
        upload_analysis_video(
            request=None,
            mode="auto",
            source_type="gallery",
            selected_style_id=None,
            selected_move_id=None,
            video=video,
            db=None,
            current_user=None,
        )

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "No video file provided"


def test_upload_analysis_video_with_selected_style_and_move(client, tmp_path):
    fake_video = tmp_path / "video.mp4"
    fake_video.write_bytes(b"fake video content")

    with patch("app.routes.analysis.run_preprocessing_pipeline") as mock_preprocessing, \
         patch("app.routes.analysis.classify_dance") as mock_classify, \
         patch("app.routes.analysis.resolve_predicted_ids") as mock_resolve_ids, \
         patch("app.routes.analysis.compute_overall_ai_score") as mock_overall, \
         patch("app.routes.analysis.compute_body_part_scores") as mock_parts, \
         patch("app.routes.analysis.generate_session_heatmaps") as mock_heatmaps, \
         patch("app.routes.analysis.upload_file_to_bucket") as mock_upload, \
         patch("app.routes.analysis.generate_llm_feedback") as mock_feedback:

        _mock_successful_pipeline(
            mock_preprocessing=mock_preprocessing,
            mock_classify=mock_classify,
            mock_resolve_ids=mock_resolve_ids,
            mock_overall=mock_overall,
            mock_parts=mock_parts,
            mock_heatmaps=mock_heatmaps,
            mock_upload=mock_upload,
            mock_feedback=mock_feedback,
            tmp_path=tmp_path,
        )

        with open(fake_video, "rb") as file:
            response = client.post(
                "/analysis/upload",
                data={
                    "mode": "learn",
                    "source_type": "gallery",
                    "selected_style_id": "1",
                    "selected_move_id": "1",
                },
                files={
                    "video": ("video.mp4", file, "video/mp4"),
                },
            )

    assert response.status_code == 201
    data = response.json()
    assert data["selected_style_id"] == 1
    assert data["selected_move_id"] == 1
    assert data["status"] == "completed"

    mock_overall.assert_called_once()
    _, kwargs = mock_overall.call_args
    assert kwargs["selected_style_name"] == "House"
    assert kwargs["selected_move_name"] == "Basic Step"


def test_safe_delete_file_ignores_empty_path():
    _safe_delete_file(None)


def test_safe_delete_file_handles_missing_file(tmp_path):
    missing_file = tmp_path / "missing.mp4"
    _safe_delete_file(str(missing_file))


def test_create_result_for_session_returns_existing_result():
    db = SessionLocal()

    try:
        session = AnalysisSession(
            user_id=1,
            mode="auto",
            source_type="gallery",
            status="uploaded",
            input_video_path="video.mp4",
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        first_result = _create_result_for_session(
            db=db,
            session=session,
            overall_score=8.0,
            arms_score=7.0,
            legs_score=9.0,
            feedback_summary="First feedback",
        )

        second_result = _create_result_for_session(
            db=db,
            session=session,
            overall_score=1.0,
            arms_score=1.0,
            legs_score=1.0,
            feedback_summary="Second feedback",
        )

        assert second_result.id == first_result.id
        assert second_result.overall_score == 8.0
        assert second_result.feedback_summary == "First feedback"

    finally:
        db.close()


def test_safe_delete_file_handles_delete_exception(monkeypatch, tmp_path):
    file_path = tmp_path / "temp.mp4"
    file_path.write_bytes(b"temporary content")

    def broken_unlink(self):
        raise OSError("cannot delete file")

    monkeypatch.setattr(Path, "unlink", broken_unlink)

    _safe_delete_file(str(file_path))


def test_full_analysis_flow_creates_result_and_updates_progress(client, tmp_path):
    upload_response = _upload_video_with_mocked_pipeline(client, tmp_path)

    assert upload_response.status_code == 201

    uploaded_session = upload_response.json()
    session_id = uploaded_session["id"]

    assert uploaded_session["status"] == "completed"
    assert uploaded_session["predicted_style_id"] == 1
    assert uploaded_session["predicted_move_id"] == 1

    result_response = client.get(f"/results/session/{session_id}")

    assert result_response.status_code == 200

    result_data = result_response.json()

    assert result_data["analysis_session_id"] == session_id
    assert result_data["overall_score"] == 8.0
    assert result_data["arms_score"] == 7.0
    assert result_data["legs_score"] == 9.0
    assert result_data["feedback_summary"] == "Good overall execution."
    assert result_data["strengths_text"] == "Good leg control."
    assert result_data["improvements_text"] == "Improve arm stability."

    history_response = client.get("/progress/history")

    assert history_response.status_code == 200

    history_data = history_response.json()

    assert isinstance(history_data, list)
    assert len(history_data) >= 1

    matching_history_items = [
        item for item in history_data
        if item["session_id"] == session_id
    ]

    assert len(matching_history_items) == 1

    history_item = matching_history_items[0]

    assert history_item["overall_score"] == 8.0
    assert "style_name" in history_item
    assert "move_name" in history_item

    stats_response = client.get("/progress/stats")

    assert stats_response.status_code == 200

    stats_data = stats_response.json()

    assert stats_data["total_sessions"] >= 1
    assert stats_data["best_score_ever"] >= 8.0