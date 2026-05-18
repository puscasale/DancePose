from unittest.mock import MagicMock, patch

import pytest

from app.ai.storage import upload_file_to_bucket


def test_upload_file_to_bucket_returns_public_url(tmp_path):
    test_file = tmp_path / "test_upload.txt"
    test_file.write_text("hello")

    fake_bucket = MagicMock()
    fake_bucket.upload.return_value = None
    fake_bucket.get_public_url.return_value = (
        "https://example.supabase.co/storage/v1/object/public/"
        "analysis-videos/debug/test_upload.txt"
    )

    fake_storage = MagicMock()
    fake_storage.from_.return_value = fake_bucket

    fake_client = MagicMock()
    fake_client.storage = fake_storage

    with patch("app.ai.storage.get_supabase_client", return_value=fake_client):
        result = upload_file_to_bucket(
            local_file_path=str(test_file),
            bucket_name="analysis-videos",
            remote_path="debug/test_upload.txt",
        )

    assert result == (
        "https://example.supabase.co/storage/v1/object/public/"
        "analysis-videos/debug/test_upload.txt"
    )

    fake_storage.from_.assert_called_with("analysis-videos")
    fake_bucket.upload.assert_called_once()
    fake_bucket.get_public_url.assert_called_once_with("debug/test_upload.txt")


def test_upload_file_to_bucket_raises_for_missing_file():
    with pytest.raises(FileNotFoundError):
        upload_file_to_bucket(
            local_file_path="missing_file.mp4",
            bucket_name="analysis-videos",
            remote_path="debug/missing_file.mp4",
        )