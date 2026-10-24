import hashlib
import json
import uuid
from datetime import datetime
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.auth import UserRegisterRequest, UserLoginRequest, UserProfileResponse
from app.core.security import get_current_user_id

router = APIRouter(prefix="/auth", tags=["Authentication"])

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
USERS_STORE_FILE = DATA_DIR / "users_store.json"

_users_db = {}

def _load_users():
    global _users_db
    try:
        if USERS_STORE_FILE.exists():
            with open(USERS_STORE_FILE, "r", encoding="utf-8") as f:
                _users_db = json.load(f)
    except Exception:
        pass

def _save_users():
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        temp_file = USERS_STORE_FILE.with_suffix(".tmp")
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(_users_db, f, indent=2, default=str)
        temp_file.replace(USERS_STORE_FILE)
    except Exception:
        pass

_load_users()

def get_deterministic_uid(email: str) -> str:
    cleaned = email.strip().lower()
    hashed = hashlib.sha256(cleaned.encode("utf-8")).hexdigest()[:12]
    return f"user_{hashed}"

@router.post("/register", response_model=UserProfileResponse)
def register(req: UserRegisterRequest):
    _load_users()
    now = datetime.utcnow().isoformat() + "Z"
    # Check if email exists
    for u in _users_db.values():
        if u["email"].lower() == req.email.lower():
            # Already registered - return existing profile rather than losing user
            return UserProfileResponse(**u)

    uid = get_deterministic_uid(req.email)
    user_data = {
        "uid": uid,
        "full_name": req.full_name,
        "email": req.email,
        "preferred_language": req.preferred_language,
        "onboarding_completed": False,
        "created_at": now,
        "updated_at": now
    }
    _users_db[uid] = user_data
    _save_users()
    return UserProfileResponse(**user_data)

@router.post("/login", response_model=UserProfileResponse)
def login(req: UserLoginRequest):
    _load_users()
    for u in _users_db.values():
        if u["email"].lower() == req.email.lower():
            return UserProfileResponse(**u)

    # If logging in for the first time with this email, create and persist consistent profile
    uid = get_deterministic_uid(req.email)
    now = datetime.utcnow().isoformat() + "Z"
    user_data = {
        "uid": uid,
        "full_name": req.email.split("@")[0].capitalize(),
        "email": req.email,
        "preferred_language": "English",
        "onboarding_completed": True,
        "created_at": now,
        "updated_at": now
    }
    _users_db[uid] = user_data
    _save_users()
    return UserProfileResponse(**user_data)

@router.get("/me", response_model=UserProfileResponse)
def get_current_user_profile(user_id: str = Depends(get_current_user_id)):
    _load_users()
    if user_id in _users_db:
        return UserProfileResponse(**_users_db[user_id])
    now = datetime.utcnow().isoformat() + "Z"
    profile = {
        "uid": user_id,
        "full_name": f"Farmer {user_id[-4:]}",
        "email": f"{user_id}@yieldcraft.ai",
        "preferred_language": "English",
        "onboarding_completed": True,
        "created_at": now,
        "updated_at": now
    }
    _users_db[user_id] = profile
    _save_users()
    return UserProfileResponse(**profile)
