from fastapi import FastAPI
from app.core.config import settings
from app.core.database import Base, engine, SessionLocal
from app.models import User, DanceStyle, DanceMove, AnalysisSession, AnalysisResult
from app.routes.auth import router as auth_router
from app.routes.styles import router as styles_router
from app.routes.moves import router as moves_router
from app.routes.analysis import router as analysis_router
from app.routes.results import router as results_router
from app.routes.profile import router as profile_router
from app.routes.progress import router as progress_router
from app.seed_data import seed_database

Base.metadata.create_all(bind=engine)

db = SessionLocal()
try:
    seed_database(db)
finally:
    db.close()

app = FastAPI(title="DancePose API")

app.include_router(auth_router)
app.include_router(styles_router)
app.include_router(moves_router)
app.include_router(analysis_router)
app.include_router(results_router)
app.include_router(profile_router)
app.include_router(progress_router)


@app.get("/")
def read_root():
    return {
        "message": "DancePose backend is running",
        "database_url_loaded": bool(settings.database_url),
    }