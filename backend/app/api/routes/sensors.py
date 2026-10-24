import uuid
from datetime import datetime
from typing import Optional, Dict, Any
from fastapi import APIRouter, status, HTTPException
from app.schemas.sensor import SensorReadingRequest, SensorReadingResponse
from app.services.farm_service import farm_service
from app.ml.model_registry import model_registry

router = APIRouter(prefix="/sensors", tags=["IoT Soil Sensors"])

@router.post("/readings", response_model=SensorReadingResponse, status_code=status.HTTP_201_CREATED)
def ingest_sensor_reading(req: SensorReadingRequest):
    reading_id = f"read_{uuid.uuid4().hex[:10]}"
    now = datetime.utcnow().isoformat() + "Z"

    reading_dict = {
        "reading_id": reading_id,
        "device_id": req.device_id,
        "farm_id": req.farm_id,
        "nitrogen": req.nitrogen,
        "phosphorus": req.phosphorus,
        "potassium": req.potassium,
        "soil_moisture": req.soil_moisture,
        "soil_temperature": req.soil_temperature,
        "battery_level_pct": req.battery_level_pct,
        "received_at": now
    }

    # Record reading and auto-sync farm soil profile
    farm_service.add_sensor_reading(req.farm_id, reading_dict)

    summary_parts = []
    if req.soil_moisture is not None:
        summary_parts.append(f"Moisture: {req.soil_moisture:.1f}%")
    if req.soil_temperature is not None:
        summary_parts.append(f"Temp: {req.soil_temperature:.1f}°C")
    if req.nitrogen is not None and req.phosphorus is not None and req.potassium is not None:
        summary_parts.append(f"NPK: {req.nitrogen:.0f}-{req.phosphorus:.0f}-{req.potassium:.0f}")

    # Compute instant live ML recommendations based on incoming telemetry
    recommended_crop = None
    recommended_fertilizer = None
    irrigation_need = None
    advisory_summary = None

    try:
        n_val = req.nitrogen if req.nitrogen is not None else 80.0
        p_val = req.phosphorus if req.phosphorus is not None else 40.0
        k_val = req.potassium if req.potassium is not None else 40.0
        temp_val = req.soil_temperature if req.soil_temperature is not None else 26.0
        moist_val = req.soil_moisture if req.soil_moisture is not None else 35.0

        # 1. Instant Crop Recommendation (Top-1)
        crop_candidates = model_registry.predict_crop(
            nitrogen=n_val,
            phosphorus=p_val,
            potassium=k_val,
            temperature=temp_val,
            humidity=65.0,
            ph=6.5,
            rainfall=120.0,
            top_n=1
        )
        if crop_candidates:
            recommended_crop = crop_candidates[0]["crop_name"]

        # 2. Instant Fertilizer Advisory for recommended or farm crop
        crop_for_fert = recommended_crop or "Rice"
        fert_res = model_registry.predict_fertilizer(
            temperature=temp_val,
            humidity=65.0,
            rainfall=120.0,
            moisture=moist_val,
            soil_type="Loamy",
            soil_ph=6.5,
            nitrogen=n_val,
            phosphorus=p_val,
            potassium=k_val,
            crop_type=crop_for_fert,
            growth_stage="Vegetative"
        )
        recommended_fertilizer = fert_res.get("recommended_fertilizer")

        # 3. Instant Irrigation Need
        irrig_res = model_registry.predict_irrigation(
            soil_type="Loamy",
            soil_ph=6.5,
            soil_moisture=moist_val,
            organic_carbon=0.5,
            electrical_conductivity=1.0,
            temperature_c=temp_val,
            humidity=65.0,
            rainfall_mm=0.0,
            sunlight_hours=7.0,
            wind_speed_kmh=10.0,
            crop_type=crop_for_fert,
            crop_growth_stage="Vegetative",
            season="Kharif",
            irrigation_type="Drip",
            water_source="Borewell",
            field_area_hectare=1.0,
            mulching_used="No",
            previous_irrigation_mm=15.0,
            region="South"
        )
        irrigation_need = irrig_res.get("irrigation_need")
        advisory_summary = f"Crop: {recommended_crop} | Fert: {recommended_fertilizer} | Irrig: {irrigation_need}"
    except Exception as e:
        advisory_summary = f"Telemetry logged. ML advisory offline: {str(e)}"

    return SensorReadingResponse(
        reading_id=reading_id,
        device_id=req.device_id,
        farm_id=req.farm_id,
        status="Ingested Successfully",
        received_at=now,
        summary=", ".join(summary_parts) if summary_parts else "Telemetry logged",
        recommended_crop=recommended_crop,
        recommended_fertilizer=recommended_fertilizer,
        irrigation_need=irrigation_need,
        advisory_summary=advisory_summary
    )

@router.get("/farms/{farm_id}", tags=["IoT Soil Sensors"])
def get_farm_sensor_readings(farm_id: str):
    return farm_service.get_sensor_readings(farm_id)

@router.get("/farms/{farm_id}/latest", tags=["IoT Soil Sensors"])
def get_latest_farm_sensor_reading(farm_id: str):
    latest = farm_service.get_latest_sensor_reading(farm_id)
    if not latest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No sensor telemetry found for farm '{farm_id}'"
        )
    return latest
