from typing import Optional
from pydantic import BaseModel, EmailStr, Field

class UserRegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2)
    email: EmailStr
    password: str = Field(..., min_length=6)
    preferred_language: str = "English"

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserProfileResponse(BaseModel):
    uid: str
    full_name: str
    email: str
    preferred_language: str
    onboarding_completed: bool
    created_at: str
    updated_at: str
