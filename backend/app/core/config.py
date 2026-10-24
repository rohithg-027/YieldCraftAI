import os
import json
from pathlib import Path
from typing import List, Union
from dotenv import load_dotenv

env_path = Path(__file__).resolve().parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)

def resolve_model_base_dir() -> str:
    env_dir = os.getenv("MODEL_BASE_DIR")
    if env_dir and Path(env_dir).exists():
        return str(Path(env_dir).resolve())
    
    # Candidate locations across local, Docker, and Render deployment environments
    candidates = [
        Path(__file__).resolve().parent.parent.parent.parent / "Models", # Repo root / Models
        Path(__file__).resolve().parent.parent.parent / "Models",        # backend / Models
        Path.cwd() / "Models",                                           # cwd / Models
        Path.cwd().parent / "Models",                                    # parent / Models
        Path("/app/Models"),                                             # Docker container default
    ]
    for c in candidates:
        if c.exists() and (c / "crop_recommendation_artifacts").exists():
            return str(c.resolve())
            
    # Default fallback to repo root Models
    return str((Path(__file__).resolve().parent.parent.parent.parent / "Models").resolve())

class Settings:
    API_HOST: str = os.getenv("API_HOST", "0.0.0.0")
    API_PORT: int = int(os.getenv("PORT", os.getenv("API_PORT", "8000")))
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    raw_origins = os.getenv("ALLOWED_ORIGINS", '["*"]')
    ALLOWED_ORIGINS: List[str] = ["*"]
    try:
        if raw_origins.startswith("[") and raw_origins.endswith("]"):
            ALLOWED_ORIGINS = json.loads(raw_origins)
        else:
            ALLOWED_ORIGINS = [x.strip() for x in raw_origins.split(",") if x.strip()]
    except Exception:
        ALLOWED_ORIGINS = ["*"]

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    DATA_GOV_IN_API_KEY: str = os.getenv("DATA_GOV_IN_API_KEY", "")

    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "yieldcraft-ai")
    FIREBASE_SERVICE_ACCOUNT_PATH: str = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "")
    FIREBASE_SERVICE_ACCOUNT_JSON: str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "")

    MODEL_BASE_DIR: str = resolve_model_base_dir()

settings = Settings()

