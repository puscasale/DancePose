from app.core.config import settings


def test_settings_property_aliases():
    assert settings.database_url == settings.DATABASE_URL
    assert settings.secret_key == settings.SECRET_KEY
    assert settings.algorithm == settings.ALGORITHM
    assert settings.access_token_expire_minutes == settings.ACCESS_TOKEN_EXPIRE_MINUTES
    assert settings.supabase_url == settings.SUPABASE_URL
    assert settings.supabase_key == settings.SUPABASE_KEY
    assert settings.supabase_videos_bucket == settings.SUPABASE_VIDEOS_BUCKET
    assert settings.supabase_heatmaps_bucket == settings.SUPABASE_HEATMAPS_BUCKET
    assert settings.gemini_api_key == settings.GEMINI_API_KEY