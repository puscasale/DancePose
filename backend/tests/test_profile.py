from app.core.database import SessionLocal
from app.models.user import User
from app.models.analysis_session import AnalysisSession
from app.models.analysis_result import AnalysisResult


def test_get_my_profile(client):
    response = client.get("/profile/me")

    assert response.status_code == 200

    data = response.json()

    assert data["id"] == 1
    assert data["email"] == "test@example.com"
    assert data["full_name"] == "Test User"
    assert data["age"] == 21
    assert data["dance_level"] == "beginner"


def test_update_my_profile(client):
    response = client.patch(
        "/profile/me",
        json={
            "full_name": "Updated User",
            "age": 25,
            "dance_level": "intermediate",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["full_name"] == "Updated User"
    assert data["age"] == 25
    assert data["dance_level"] == "intermediate"

    db = SessionLocal()

    try:
        user = db.query(User).filter(User.id == 1).first()

        assert user is not None
        assert user.full_name == "Updated User"
        assert user.age == 25
        assert user.dance_level == "intermediate"

    finally:
        db.close()


def test_change_password_success(raw_client):
    login_response = raw_client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": "testing123",
        },
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    response = raw_client.patch(
        "/profile/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "current_password": "testing123",
            "new_password": "newpassword123",
        },
    )

    assert response.status_code == 200
    assert response.json()["message"] == "Password updated successfully"

    login_response = raw_client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": "newpassword123",
        },
    )

    assert login_response.status_code == 200
    assert "access_token" in login_response.json()


def test_change_password_rejects_wrong_current_password(client):
    response = client.patch(
        "/profile/change-password",
        json={
            "current_password": "wrongpassword",
            "new_password": "newpassword123",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Current password is incorrect"


def test_change_password_rejects_short_new_password(client):
    response = client.patch(
        "/profile/change-password",
        json={
            "current_password": "testing123",
            "new_password": "short",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "New password must be at least 8 characters long"


def test_delete_my_account(client):
    response = client.delete("/profile/me")

    assert response.status_code == 200
    assert response.json()["message"] == "Account deleted successfully"

    db = SessionLocal()

    try:
        user = db.query(User).filter(User.id == 1).first()
        assert user is None

    finally:
        db.close()

def test_delete_my_account_with_existing_sessions_and_results(client):
    db = SessionLocal()
    try:
        session = AnalysisSession(
            user_id=1,
            mode="auto",
            source_type="gallery",
            status="completed",
            input_video_path="https://supabase.test/video.mp4",
            selected_style_id=1,
            selected_move_id=1,
            predicted_style_id=1,
            predicted_move_id=1,
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        result = AnalysisResult(
            analysis_session_id=session.id,
            overall_score=8.0,
            arms_score=7.0,
            legs_score=9.0,
            feedback_summary="Good execution.",
            strengths_text="Good timing.",
            improvements_text="Improve arm control.",
        )
        db.add(result)
        db.commit()

        session_id = session.id
    finally:
        db.close()

    response = client.delete("/profile/me")

    assert response.status_code == 200
    assert response.json()["message"] == "Account deleted successfully"

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == 1).first()
        deleted_session = db.query(AnalysisSession).filter(AnalysisSession.id == session_id).first()
        deleted_result = (
            db.query(AnalysisResult)
            .filter(AnalysisResult.analysis_session_id == session_id)
            .first()
        )

        assert user is None
        assert deleted_session is None
        assert deleted_result is None
    finally:
        db.close()