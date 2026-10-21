import base64
import json
import logging
from typing import Optional, Dict, Any
from fastapi import Header, HTTPException, status
from .firebase import firebase_manager

logger = logging.getLogger("ai_tourist.security")

def verify_firebase_token(authorization: Optional[str] = Header(None)) -> Dict[str, Any]:
    """
    Verifies incoming Firebase ID token from Authorization header:
    Authorization: Bearer <id_token>
    
    If Firebase credentials are live, strictly enforces JWT validation via Firebase Admin.
    If in local/offline mode, extracts real user claims from token payload safely.
    """
    if not authorization or not authorization.startswith("Bearer "):
        if firebase_manager.is_live:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Bearer Authorization token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        # Development default
        return {"uid": "usr_mayank", "email": "mayankpawar@gmail.com", "name": "Mayank Pawar", "is_mock": True}

    token = authorization.split("Bearer ")[1].strip()

    if firebase_manager.is_live:
        try:
            from firebase_admin import auth
            decoded_token = auth.verify_id_token(token)
            return decoded_token
        except Exception as e:
            logger.error(f"Firebase token verification failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid or expired Firebase token: {str(e)}",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # Safe token decoding for local development / offline authentication
    if "." in token:
        try:
            parts = token.split(".")
            if len(parts) >= 2:
                payload_b64 = parts[1]
                rem = len(payload_b64) % 4
                if rem:
                    payload_b64 += "=" * (4 - rem)
                claims = json.loads(base64.urlsafe_b64decode(payload_b64.encode()).decode("utf-8", "ignore"))
                uid = claims.get("user_id") or claims.get("sub") or claims.get("uid")
                if uid:
                    return {
                        "uid": uid,
                        "email": claims.get("email", ""),
                        "name": claims.get("name", claims.get("email", "").split("@")[0] if claims.get("email") else "Traveler"),
                        "token": token,
                        "is_mock": True,
                    }
        except Exception as e:
            logger.debug(f"Could not parse token claims: {e}")

    # Explicit user ID tokens (e.g. usr_123 or user email)
    if token.startswith("usr_") or "@" in token:
        return {"uid": token, "email": token if "@" in token else "user@aitourist.org", "name": "Authenticated User", "is_mock": True}

    # Deterministic hash fallback for arbitrary tokens
    hashed_id = f"usr_{abs(hash(token)) % 1000000}"
    return {"uid": hashed_id, "token": token, "is_mock": True}
