from datetime import datetime, timezone

from app.core.database import SessionLocal
from app.models.analysis_session import AnalysisSession


def _create_completed_session(db):
    session = AnalysisSession(
        user_id=1,
        mode="auto",
        source_type="gallery",
        status="uploaded",
        input_video_path="https://supabase.test/video.mp4",
        selected_style_id=1,
        selected_move_id=1,
        predicted_style_id=1,
        predicted_move_id=1,
        completed_at=datetime.now(timezone.utc),
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


def _create_result_payload(session_id: int):
    return {
        "analysis_session_id": session_id,
        "overall_score": 8.5,
        "arms_score": 7.5,
        "legs_score": 9.0,
        "feedback_summary": "Good execution.",
        "strengths_text": "Strong lower body control.",
        "improvements_text": "Improve arm stability.",
        "best_expert_file": "expert.npy",
        "best_novice_frame": 30,
        "best_expert_frame": 28,
        "worst_novice_frame": 90,
        "worst_expert_frame": 88,
        "problematic_joints_text": "left wrist, right elbow",
        "best_heatmap_url": "https://supabase.test/best.png",
        "worst_heatmap_url": "https://supabase.test/worst.png",
    }


def test_create_analysis_result_success(client):
    db = SessionLocal()

    try:
        session = _create_completed_session(db)
        session_id = session.id

    finally:
        db.close()

    response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )

    assert response.status_code == 201

    data = response.json()

    assert data["analysis_session_id"] == session_id
    assert data["overall_score"] == 8.5
    assert data["arms_score"] == 7.5
    assert data["legs_score"] == 9.0
    assert data["feedback_summary"] == "Good execution."
    assert data["predicted_style_name"] == "House"
    assert data["predicted_move_name"] == "Basic Step"


def test_create_analysis_result_rejects_duplicate_result(client):
    db = SessionLocal()

    try:
        session = _create_completed_session(db)
        session_id = session.id

    finally:
        db.close()

    first_response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )
    second_response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 400
    assert second_response.json()["detail"] == "A result already exists for this session"


def test_create_analysis_result_missing_session_returns_404(client):
    response = client.post(
        "/results/",
        json=_create_result_payload(999999),
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Analysis session not found"


def test_get_result_for_session_success(client):
    db = SessionLocal()

    try:
        session = _create_completed_session(db)
        session_id = session.id

    finally:
        db.close()

    create_response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )

    assert create_response.status_code == 201

    response = client.get(f"/results/session/{session_id}")

    assert response.status_code == 200

    data = response.json()

    assert data["analysis_session_id"] == session_id
    assert data["overall_score"] == 8.5
    assert data["predicted_style_name"] == "House"
    assert data["predicted_move_name"] == "Basic Step"


def test_get_result_for_missing_session_returns_404(client):
    response = client.get("/results/session/999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Analysis session not found"


def test_progress_history_returns_sessions(client):
    db = SessionLocal()

    try:
        session = _create_completed_session(db)
        session_id = session.id

    finally:
        db.close()

    create_response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )

    assert create_response.status_code == 201

    response = client.get("/progress/history")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["session_id"] == session_id
    assert data[0]["overall_score"] == 8.5
    assert data[0]["style_name"] == "House"
    assert data[0]["move_name"] == "Basic Step"


def test_progress_stats_returns_expected_values(client):
    db = SessionLocal()

    try:
        session = _create_completed_session(db)
        session_id = session.id

    finally:
        db.close()

    create_response = client.post(
        "/results/",
        json=_create_result_payload(session_id),
    )

    assert create_response.status_code == 201

    response = client.get("/progress/stats")

    assert response.status_code == 200

    data = response.json()

    assert data["best_score_ever"] == 8.5
    assert data["total_sessions"] == 1
    assert data["most_practiced_move"] == "Basic Step"
    assert len(data["average_by_style"]) == 1
    assert data["average_by_style"][0]["style_name"] == "House"
    assert data["average_by_style"][0]["average_score"] == 8.5