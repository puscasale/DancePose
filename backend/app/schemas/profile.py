from pydantic import BaseModel, EmailStr


class UserProfileUpdate(BaseModel):
    full_name: str
    age: int | None = None
    dance_level: str | None = None


class UserProfileResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    age: int | None = None
    dance_level: str | None = None

    class Config:
        from_attributes = True


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str