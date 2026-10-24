import os
import json
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Any
from pathlib import Path
from fastapi import HTTPException, status
from app.schemas.farm import FarmCreateRequest, FarmUpdateRequest, FarmResponse
from app.schemas.soil import SoilProfileCreateRequest, SoilProfileResponse

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
FARMS_STORE_FILE = DATA_DIR / "farms_store.json"

def get_dynamic_ph_for_soil_type(soil_type: Optional[str]) -> float:
    if not soil_type:
        return 6.6
    st = str(soil_type).lower().strip()
    if st == "black":
        return 7.6
    elif st == "clay":
        return 7.2
    elif st == "alluvial":
        return 7.0
    elif st == "loamy":
        return 6.6
    elif st == "sandy":
        return 6.2
    elif st == "red":
        return 5.9
    elif st == "laterite":
        return 5.3
    return 6.5

class FarmService:
    def __init__(self):
        # In-memory store: farm_id -> dict
        self._farms: Dict[str, Dict[str, Any]] = {}
        # soil_profiles: farm_id -> List[dict]
        self._soil_profiles: Dict[str, List[Dict[str, Any]]] = {}
        # sensor_readings: farm_id -> List[dict]
        self._sensor_readings: Dict[str, List[Dict[str, Any]]] = {}
        # diary_entries: farm_id -> List[dict]
        self._diary_entries: Dict[str, List[Dict[str, Any]]] = {}

        self._load_from_disk()

    def _load_from_disk(self):
        try:
            if FARMS_STORE_FILE.exists():
                with open(FARMS_STORE_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self._farms = data.get("farms", {})
                    self._soil_profiles = data.get("soil_profiles", {})
                    self._sensor_readings = data.get("sensor_readings", {})
                    self._diary_entries = data.get("diary_entries", {})
        except Exception:
            pass

    def _save_to_disk(self):
        try:
            DATA_DIR.mkdir(parents=True, exist_ok=True)
            temp_file = FARMS_STORE_FILE.with_suffix(".tmp")
            data = {
                "farms": self._farms,
                "soil_profiles": self._soil_profiles,
                "sensor_readings": self._sensor_readings,
                "diary_entries": self._diary_entries,
            }
            with open(temp_file, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, default=str)
            temp_file.replace(FARMS_STORE_FILE)
        except Exception:
            pass

    def create_farm(self, owner_uid: str, req: FarmCreateRequest) -> FarmResponse:
        farm_id = f"farm_{uuid.uuid4().hex[:10]}"
        now = datetime.utcnow().isoformat() + "Z"
        farm_data = {
            "farm_id": farm_id,
            "owner_uid": owner_uid,
            "farm_name": req.farm_name,
            "latitude": req.latitude,
            "longitude": req.longitude,
            "location_accuracy_meters": req.location_accuracy_meters,
            "address": req.address,
            "village": req.village,
            "district": req.district,
            "state": req.state,
            "country": req.country,
            "area": req.area,
            "area_unit": req.area_unit,
            "soil_type": req.soil_type,
            "irrigation_source": req.irrigation_source,
            "active_crop": req.active_crop,
            "created_at": now,
            "updated_at": now
        }
        self._farms[farm_id] = farm_data
        self._save_to_disk()
        return FarmResponse(**farm_data)

    def list_farms_for_user(self, owner_uid: str) -> List[FarmResponse]:
        user_farms = [
            FarmResponse(**f) for f in self._farms.values()
            if f.get("owner_uid") == owner_uid
        ]
        if not user_farms and owner_uid.startswith("user_"):
            legacy_uids = {"user_34ba5be9f0c4", "user_e4ade7254a04"}
            if owner_uid in legacy_uids:
                user_farms = [
                    FarmResponse(**f) for f in self._farms.values()
                    if f.get("owner_uid") in legacy_uids
                ]
                for f in self._farms.values():
                    if f.get("owner_uid") in legacy_uids:
                        f["owner_uid"] = owner_uid
                if user_farms:
                    self._save_to_disk()
        return user_farms

    def get_farm(self, owner_uid: str, farm_id: str) -> FarmResponse:
        farm = self._farms.get(farm_id)
        if not farm:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Farm with id '{farm_id}' not found"
            )
        if farm.get("owner_uid") != owner_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this farm"
            )
        return FarmResponse(**farm)

    def update_farm(self, owner_uid: str, farm_id: str, req: FarmUpdateRequest) -> FarmResponse:
        farm = self._farms.get(farm_id)
        if not farm:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Farm with id '{farm_id}' not found"
            )
        if farm.get("owner_uid") != owner_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to update this farm"
            )

        update_dict = req.model_dump(exclude_unset=True)
        for k, v in update_dict.items():
            if v is not None:
                farm[k] = v
        farm["updated_at"] = datetime.utcnow().isoformat() + "Z"
        self._save_to_disk()
        return FarmResponse(**farm)

    def delete_farm(self, owner_uid: str, farm_id: str):
        farm = self._farms.get(farm_id)
        if not farm:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Farm with id '{farm_id}' not found"
            )
        if farm.get("owner_uid") != owner_uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to delete this farm"
            )
        del self._farms[farm_id]
        if farm_id in self._soil_profiles:
            del self._soil_profiles[farm_id]
        if farm_id in self._diary_entries:
            del self._diary_entries[farm_id]
        if farm_id in self._sensor_readings:
            del self._sensor_readings[farm_id]
        self._save_to_disk()

    def add_soil_profile(self, owner_uid: str, farm_id: str, req: SoilProfileCreateRequest) -> SoilProfileResponse:
        # Verify farm ownership first
        self.get_farm(owner_uid, farm_id)

        profile_id = f"soil_{uuid.uuid4().hex[:10]}"
        now = datetime.utcnow().isoformat() + "Z"
        soil_type = req.soil_type or "Loamy"
        ph_val = req.ph
        if ph_val is None or ph_val == 0.0:
            ph_val = get_dynamic_ph_for_soil_type(soil_type)

        profile_data = {
            "profile_id": profile_id,
            "farm_id": farm_id,
            "nitrogen": req.nitrogen,
            "phosphorus": req.phosphorus,
            "potassium": req.potassium,
            "ph": ph_val,
            "moisture": req.moisture,
            "soil_temperature": req.soil_temperature,
            "electrical_conductivity": req.electrical_conductivity,
            "organic_carbon": req.organic_carbon,
            "soil_type": soil_type,
            "test_date": req.test_date or datetime.utcnow().strftime("%Y-%m-%d"),
            "lab_name": req.lab_name,
            "source": req.source,
            "created_at": now
        }
        if farm_id not in self._soil_profiles:
            self._soil_profiles[farm_id] = []
        self._soil_profiles[farm_id].insert(0, profile_data)
        self._save_to_disk()
        return SoilProfileResponse(**profile_data)

    def list_soil_profiles(self, owner_uid: str, farm_id: str) -> List[SoilProfileResponse]:
        self.get_farm(owner_uid, farm_id)
        profiles = self._soil_profiles.get(farm_id, [])
        return [SoilProfileResponse(**p) for p in profiles]

    def get_latest_soil_profile(self, owner_uid: str, farm_id: str) -> Optional[SoilProfileResponse]:
        self.get_farm(owner_uid, farm_id)
        profiles = self._soil_profiles.get(farm_id, [])
        if profiles:
            return SoilProfileResponse(**profiles[0])
        return None

    def add_sensor_reading(self, farm_id: str, reading: Dict[str, Any]):
        if farm_id not in self._sensor_readings:
            self._sensor_readings[farm_id] = []
        self._sensor_readings[farm_id].insert(0, reading)

        # Dynamic pH based on farm soil type
        farm = self._farms.get(farm_id)
        soil_type = farm.get("soil_type", "Loamy") if farm else "Loamy"
        dyn_ph = get_dynamic_ph_for_soil_type(soil_type)

        # Auto-synchronize telemetry into farm soil profile so Crop, Fertilizer, and Irrigation models use live IoT data
        existing_profiles = self._soil_profiles.get(farm_id, [])
        if existing_profiles:
            latest = existing_profiles[0]
            if reading.get("nitrogen") is not None:
                latest["nitrogen"] = reading["nitrogen"]
            if reading.get("phosphorus") is not None:
                latest["phosphorus"] = reading["phosphorus"]
            if reading.get("potassium") is not None:
                latest["potassium"] = reading["potassium"]
            if reading.get("soil_moisture") is not None:
                latest["moisture"] = reading["soil_moisture"]
            if reading.get("soil_temperature") is not None:
                latest["soil_temperature"] = reading["soil_temperature"]
            latest["ph"] = dyn_ph
            latest["soil_type"] = soil_type
            latest["source"] = f"IoT Device {reading.get('device_id', 'ESP32')}"
        elif reading.get("nitrogen") is not None or reading.get("soil_moisture") is not None or reading.get("soil_temperature") is not None:
            # Create initial profile from IoT data
            profile_id = f"soil_iot_{uuid.uuid4().hex[:8]}"
            now = datetime.utcnow().isoformat() + "Z"
            profile_data = {
                "profile_id": profile_id,
                "farm_id": farm_id,
                "nitrogen": reading.get("nitrogen", 85.0),
                "phosphorus": reading.get("phosphorus", 42.0),
                "potassium": reading.get("potassium", 44.0),
                "ph": dyn_ph,
                "moisture": reading.get("soil_moisture", 45.0),
                "soil_temperature": reading.get("soil_temperature", 26.0),
                "electrical_conductivity": 0.5,
                "organic_carbon": 0.6,
                "soil_type": soil_type,
                "test_date": datetime.utcnow().strftime("%Y-%m-%d"),
                "lab_name": f"ESP32 Node ({reading.get('device_id', 'Live')})",
                "source": "ESP32 IoT Sensor Telemetry",
                "created_at": now
            }
            self._soil_profiles[farm_id] = [profile_data]
        self._save_to_disk()

    def get_sensor_readings(self, farm_id: str) -> List[Dict[str, Any]]:
        return self._sensor_readings.get(farm_id, [])

    def get_latest_sensor_reading(self, farm_id: str) -> Optional[Dict[str, Any]]:
        readings = self._sensor_readings.get(farm_id, [])
        return readings[0] if readings else None

    def add_diary_entry(self, owner_uid: str, farm_id: str, entry: Dict[str, Any]) -> Dict[str, Any]:
        self.get_farm(owner_uid, farm_id)
        if farm_id not in self._diary_entries:
            self._diary_entries[farm_id] = []
        entry["entry_id"] = f"entry_{uuid.uuid4().hex[:10]}"
        entry["created_at"] = datetime.utcnow().isoformat() + "Z"
        self._diary_entries[farm_id].insert(0, entry)
        self._save_to_disk()
        return entry

    def list_diary_entries(self, owner_uid: str, farm_id: str) -> List[Dict[str, Any]]:
        self.get_farm(owner_uid, farm_id)
        return self._diary_entries.get(farm_id, [])

farm_service = FarmService()
