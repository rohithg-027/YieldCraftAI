from datetime import datetime
from fastapi import APIRouter, Depends
from app.schemas.irrigation import (
    IrrigationRecommendationRequest,
    IrrigationRecommendationResponse
)
from app.core.security import get_current_user_id
from app.ml.model_registry import model_registry

router = APIRouter(prefix="/irrigation", tags=["Irrigation Recommendation"])

ACTION_TIPS = {
    "High": (
        "Irrigation is urgently required. Soil moisture has dropped below critical depletion levels for the crop root zone. Apply irrigation within the next 12-24 hours.",
        "Consider drip irrigation or scheduled furrow watering early in the morning (6:00 AM - 9:00 AM) to minimize evapotranspiration losses."
    ),
    "Medium": (
        "Moderate soil moisture detected. Prepare for irrigation in 2-3 days, unless incoming rainfall forecast materializes.",
        "Inspect root zone depth (15-30 cm) and apply organic mulching to conserve moisture in high temperatures."
    ),
    "Low": (
        "Soil moisture is adequate and root zone hydration is optimal. No irrigation required today.",
        "Avoid overwatering to prevent root asphyxiation, nutrient leaching, and root rot pathogens."
    )
}

@router.post("/recommend", response_model=IrrigationRecommendationResponse)
def recommend_irrigation(
    req: IrrigationRecommendationRequest,
    user_id: str = Depends(get_current_user_id)
):
    result = model_registry.predict_irrigation(
        soil_type=req.soil_type,
        soil_ph=req.soil_ph,
        soil_moisture=req.soil_moisture,
        organic_carbon=req.organic_carbon,
        electrical_conductivity=req.electrical_conductivity,
        temperature_c=req.temperature_c,
        humidity=req.humidity,
        rainfall_mm=req.rainfall_mm,
        sunlight_hours=req.sunlight_hours,
        wind_speed_kmh=req.wind_speed_kmh,
        crop_type=req.crop_type,
        crop_growth_stage=req.crop_growth_stage,
        season=req.season,
        irrigation_type=req.irrigation_type,
        water_source=req.water_source,
        field_area_hectare=req.field_area_hectare,
        mulching_used=req.mulching_used,
        previous_irrigation_mm=req.previous_irrigation_mm,
        region=req.region
    )

    need = result["irrigation_need"]
    action, conservation = ACTION_TIPS.get(
        need,
        (
            f"Irrigation need assessed as {need}. Monitor field moisture status.",
            "Utilize localized drip emitters for highest water-use efficiency."
        )
    )

    return IrrigationRecommendationResponse(
        irrigation_need=need,
        probabilities=result["probabilities"],
        soil_moisture=req.soil_moisture,
        rainfall_context=req.rainfall_mm,
        recommended_action=action,
        water_conservation_tip=conservation,
        model_version="CatBoost-Irrigation-Pipeline-v1.0 (High/Medium/Low)",
        timestamp=datetime.utcnow().isoformat() + "Z"
    )
