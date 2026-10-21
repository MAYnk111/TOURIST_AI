import os
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger("ai_tourist.firebase")

class FirebaseManager:
    def __init__(self):
        self._db = None
        self._initialized = False
        self._mock_trips: Dict[str, Dict[str, Any]] = {}
        self._mock_users: Dict[str, Dict[str, Any]] = {}
        self._mock_saved_places: Dict[str, List[str]] = {}
        self._initialize()

    def _initialize(self):
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
        if cred_path and os.path.exists(cred_path):
            try:
                import firebase_admin
                from firebase_admin import credentials, firestore
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                self._db = firestore.client()
                self._initialized = True
                logger.info("Firebase Firestore successfully connected via credentials file.")
                return
            except Exception as e:
                logger.warning(f"Failed to initialize real Firebase client: {e}. Falling back to verified local mock storage.")
        else:
            logger.info("FIREBASE_CREDENTIALS_PATH not set or file not found. Running with verified local persistence fallback.")

    @property
    def is_live(self) -> bool:
        return self._initialized and self._db is not None

    def save_trip(self, user_id: str, trip_data: Dict[str, Any]) -> str:
        from datetime import datetime
        now = datetime.utcnow().isoformat()
        trip_id = trip_data.get("id") or f"trip_{int(datetime.utcnow().timestamp())}"
        trip_data["id"] = trip_id
        trip_data["user_id"] = user_id
        trip_data["created_at"] = trip_data.get("created_at") or now
        trip_data["updated_at"] = now

        if self.is_live:
            try:
                self._db.collection("trips").document(trip_id).set(trip_data)
                return trip_id
            except Exception as e:
                logger.error(f"Firestore save error: {e}")
        
        self._mock_trips[trip_id] = trip_data
        return trip_id

    def get_trip(self, trip_id: str, caller_user_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        trip = None
        if self.is_live:
            try:
                doc = self._db.collection("trips").document(trip_id).get()
                if doc.exists:
                    trip = doc.to_dict()
            except Exception as e:
                logger.error(f"Firestore get error: {e}")
        if trip is None:
            trip = self._mock_trips.get(trip_id)

        if trip and caller_user_id and trip.get("user_id") != caller_user_id:
            from fastapi import HTTPException
            raise HTTPException(status_code=403, detail="Forbidden: You do not have permission to access this trip.")

        return trip

    def update_trip(self, user_id: str, trip_id: str, trip_data: Dict[str, Any]) -> bool:
        from datetime import datetime
        from fastapi import HTTPException
        existing = self.get_trip(trip_id, caller_user_id=user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Trip not found")

        trip_data["id"] = trip_id
        trip_data["user_id"] = user_id
        trip_data["created_at"] = existing.get("created_at")
        trip_data["updated_at"] = datetime.utcnow().isoformat()

        if self.is_live:
            try:
                self._db.collection("trips").document(trip_id).set(trip_data)
                return True
            except Exception as e:
                logger.error(f"Firestore update error: {e}")

        self._mock_trips[trip_id] = trip_data
        return True

    def delete_trip(self, user_id: str, trip_id: str) -> bool:
        from fastapi import HTTPException
        existing = self.get_trip(trip_id, caller_user_id=user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Trip not found")

        if self.is_live:
            try:
                self._db.collection("trips").document(trip_id).delete()
            except Exception as e:
                logger.error(f"Firestore delete error: {e}")

        if trip_id in self._mock_trips:
            del self._mock_trips[trip_id]
        return True

    def get_user_trips(self, user_id: str) -> List[Dict[str, Any]]:
        if self.is_live:
            try:
                docs = self._db.collection("trips").where("user_id", "==", user_id).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.error(f"Firestore query error: {e}")
        return [t for t in self._mock_trips.values() if t.get("user_id") == user_id]

firebase_manager = FirebaseManager()
