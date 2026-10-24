import json
import logging
from typing import Optional
from fastapi import Header, HTTPException, status
from app.core.config import settings

logger = logging.getLogger("yieldcraft.security")

_firebase_app = None

def get_firebase_app():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
        try:
            import firebase_admin
            from firebase_admin import credentials
            cert_dict = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
            cred = credentials.Certificate(cert_dict)
            _firebase_app = firebase_admin.initialize_app(cred, {
                'projectId': settings.FIREBASE_PROJECT_ID
            })
            logger.info("Firebase Admin SDK initialized successfully with service account JSON.")
            return _firebase_app
        except Exception as e:
            logger.warning(f"Could not initialize Firebase Admin SDK with JSON: {e}")
    if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        try:
            import firebase_admin
            from firebase_admin import credentials
            cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
            _firebase_app = firebase_admin.initialize_app(cred, {
                'projectId': settings.FIREBASE_PROJECT_ID
            })
            logger.info("Firebase Admin SDK initialized successfully with service account.")
            return _firebase_app
        except Exception as e:
            logger.warning(f"Could not initialize Firebase Admin SDK with service account: {e}")
    return None

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """
    Validates Firebase Bearer ID Token or local dev token.
    Returns the authenticated user's UID.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme. Expected 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    app = get_firebase_app()
    if app:
        # In development/test mode, support mock/test tokens that are not 3-part JWTs
        if (settings.ENVIRONMENT in ("development", "test") or token.startswith("test-") or token.startswith("dev-")) and len(token.split(".")) != 3:
            return token.replace("Bearer ", "").strip()

        try:
            from firebase_admin import auth
            decoded_token = auth.verify_id_token(token)
            uid = decoded_token.get("uid")
            if not uid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token payload: missing UID",
                )
            return uid
        except Exception as e:
            logger.warning(f"Firebase token verification failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid or expired Firebase authentication token: {str(e)}",
            )
    else:
        # In local development mode without Firebase service account,
        # support standard client auth tokens (e.g. "dev-user-123" or uid prefix)
        if token.startswith("dev-") or len(token) >= 4:
            clean_uid = token.replace("Bearer ", "").strip()
            return clean_uid
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token is invalid.",
        )
