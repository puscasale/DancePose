from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = BASE_DIR / ".env"


class Settings(BaseSettings):
    DATABASE_URL: str

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_VIDEOS_BUCKET: str = "analysis-videos"
    SUPABASE_HEATMAPS_BUCKET: str = "analysis-heatmaps"

    GEMINI_API_KEY: str | None = None

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def database_url(self) -> str:
        return self.DATABASE_URL

    @property
    def secret_key(self) -> str:
        return self.SECRET_KEY

    @property
    def algorithm(self) -> str:
        return self.ALGORITHM

    @property
    def access_token_expire_minutes(self) -> int:
        return self.ACCESS_TOKEN_EXPIRE_MINUTES

    @property
    def supabase_url(self) -> str:
        return self.SUPABASE_URL

    @property
    def supabase_key(self) -> str:
        return self.SUPABASE_KEY

    @property
    def supabase_videos_bucket(self) -> str:
        return self.SUPABASE_VIDEOS_BUCKET

    @property
    def supabase_heatmaps_bucket(self) -> str:
        return self.SUPABASE_HEATMAPS_BUCKET

    @property
    def gemini_api_key(self) -> str | None:
        return self.GEMINI_API_KEY


settings = Settings()