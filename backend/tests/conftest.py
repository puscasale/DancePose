import os
import shutil
from pathlib import Path

import pytest
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session


BASE_DIR = Path(__file__).resolve().parents[1]
TEST_DB_PATH = BASE_DIR / "test_dancepose.db"

if TEST_DB_PATH.exists():
    TEST_DB_PATH.chmod(0o666)
    TEST_DB_PATH.unlink()

for suffix in ["-journal", "-wal", "-shm"]:
    extra_file = Path(str(TEST_DB_PATH) + suffix)
    if extra_file.exists():
        extra_file.chmod(0o666)
        extra_file.unlink()


os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"
os.environ["SECRET_KEY"] = "test_secret_key"
os.environ["ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "60"

os.environ["SUPABASE_URL"] = "https://test.supabase.co"
os.environ["SUPABASE_KEY"] = "test_key"
os.environ["SUPABASE_VIDEOS_BUCKET"] = "analysis-videos"
os.environ["SUPABASE_HEATMAPS_BUCKET"] = "analysis-heatmaps"
os.environ["GEMINI_API_KEY"] = ""


Path("media").mkdir(exist_ok=True)
Path("uploads").mkdir(exist_ok=True)


from app.main import app  # noqa: E402
from app.core.database import Base, engine, SessionLocal, get_db  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.routes.dependencies import get_current_user  # noqa: E402
from app.models.user import User  # noqa: E402
from app.models.dance_style import DanceStyle  # noqa: E402
from app.models.dance_move import DanceMove  # noqa: E402


def _model_kwargs(model_class, values: dict) -> dict:
    existing_columns = {column.name for column in model_class.__table__.columns}
    return {key: value for key, value in values.items() if key in existing_columns}


def _create_test_style(db: Session):
    style = DanceStyle(
        **_model_kwargs(
            DanceStyle,
            {
                "id": 1,
                "name": "House",
                "description": "House dance style used for automated tests.",
                "image_url": None,
                "cover_image_url": None,
            },
        )
    )

    db.add(style)
    db.commit()
    db.refresh(style)

    return style


def _create_test_move(db: Session):
    move = DanceMove(
        **_model_kwargs(
            DanceMove,
            {
                "id": 1,
                "name": "Basic Step",
                "description": "Basic step used for automated tests.",
                "style_id": 1,
                "dance_style_id": 1,
                "reference_video_url": None,
                "video_url": None,
                "image_url": None,
            },
        )
    )

    db.add(move)
    db.commit()
    db.refresh(move)

    return move


@pytest.fixture(autouse=True)
def setup_test_database():

    engine.dispose()

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        user = User(
            id=1,
            full_name="Test User",
            email="test@example.com",
            password_hash=hash_password("testing123"),
            age=21,
            dance_level="beginner",
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        _create_test_style(db)
        _create_test_move(db)

    finally:
        db.close()

    yield

    engine.dispose()

    Base.metadata.drop_all(bind=engine)

    engine.dispose()

    if Path("uploads").exists():
        shutil.rmtree("uploads", ignore_errors=True)

    Path("uploads").mkdir(exist_ok=True)


@pytest.fixture(scope="session", autouse=True)
def cleanup_test_files_after_session():
    yield

    engine.dispose()

    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()

    for suffix in ["-journal", "-wal", "-shm"]:
        extra_file = Path(str(TEST_DB_PATH) + suffix)
        if extra_file.exists():
            extra_file.unlink()


def override_get_current_user(db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == 1).first()


@pytest.fixture()
def client():
    app.dependency_overrides[get_current_user] = override_get_current_user

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest.fixture()
def raw_client():
    app.dependency_overrides.clear()

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()