from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import verify_password, hash_password
from app.models.user import User
from app.models.analysis_session import AnalysisSession
from app.models.analysis_result import AnalysisResult
from app.routes.dependencies import get_current_user
from app.schemas.profile import (
    UserProfileUpdate,
    UserProfileResponse,
    ChangePasswordRequest,
)

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/me", response_model=UserProfileResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.patch("/me", response_model=UserProfileResponse)
def update_my_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.full_name = profile_data.full_name.strip()

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return current_user


@router.patch("/change-password")
def change_password(
    password_data: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(password_data.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")

    if len(password_data.new_password) < 8:
        raise HTTPException(
            status_code=400,
            detail="New password must be at least 8 characters long",
        )

    current_user.password_hash = hash_password(password_data.new_password)

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return {"message": "Password updated successfully"}


@router.delete("/me")
def delete_my_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sessions = (
        db.query(AnalysisSession)
        .filter(AnalysisSession.user_id == current_user.id)
        .all()
    )

    session_ids = [session.id for session in sessions]

    if session_ids:
        (
            db.query(AnalysisResult)
            .filter(AnalysisResult.analysis_session_id.in_(session_ids))
            .delete(synchronize_session=False)
        )

        (
            db.query(AnalysisSession)
            .filter(AnalysisSession.user_id == current_user.id)
            .delete(synchronize_session=False)
        )

    db.delete(current_user)
    db.commit()

    return {"message": "Account deleted successfully"}