import mimetypes
from pathlib import Path

from supabase import create_client, Client

from app.core.config import settings


def get_supabase_client() -> Client:
    supabase_url = (settings.SUPABASE_URL or "").strip().rstrip("/")
    supabase_key = (settings.SUPABASE_KEY or "").strip()

    if not supabase_url:
        raise RuntimeError("SUPABASE_URL is missing. Check your .env file.")

    if not supabase_url.startswith("https://"):
        raise RuntimeError(
            f"SUPABASE_URL is invalid: {supabase_url}. "
            "It must start with https://"
        )

    if not supabase_key:
        raise RuntimeError("SUPABASE_KEY is missing. Check your .env file.")

    return create_client(supabase_url, supabase_key)


def upload_file_to_bucket(
    local_file_path: str,
    bucket_name: str,
    remote_path: str,
) -> str:
    local_path = Path(local_file_path)

    if not local_path.exists():
        raise FileNotFoundError(f"File does not exist: {local_file_path}")

    if not bucket_name:
        raise RuntimeError("Bucket name is missing.")

    supabase = get_supabase_client()

    content_type, _ = mimetypes.guess_type(str(local_path))
    if content_type is None:
        content_type = "application/octet-stream"

    with open(local_path, "rb") as file:
        supabase.storage.from_(bucket_name).upload(
            path=remote_path,
            file=file,
            file_options={
                "content-type": content_type,
                "upsert": "true",
            },
        )

    public_url = supabase.storage.from_(bucket_name).get_public_url(remote_path)

    return public_url