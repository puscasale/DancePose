from pydantic import BaseModel, EmailStr


class UserProfileUpdate(BaseModel):
    full_name: str


class UserProfileResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr

    class Config:
        from_attributes = True


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str