import os
import base64
import hashlib
import hmac
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from app.core.config import settings


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    hashed = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        100_000,
    )
    return base64.b64encode(salt + hashed).decode("utf-8")


def verify_password(plain_password: str, stored_password: str) -> bool:
    decoded = base64.b64decode(stored_password.encode("utf-8"))
    salt = decoded[:16]
    stored_hash = decoded[16:]

    new_hash = hashlib.pbkdf2_hmac(
        "sha256",
        plain_password.encode("utf-8"),
        salt,
        100_000,
    )

    return hmac.compare_digest(stored_hash, new_hash)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    to_encode.update({"exp": expire})

    return jwt.encode(
        to_encode,
        settings.secret_key,
        algorithm=settings.algorithm,
    )


def decode_access_token(token: str) -> dict:
    return jwt.decode(
        token,
        settings.secret_key,
        algorithms=[settings.algorithm],
    )