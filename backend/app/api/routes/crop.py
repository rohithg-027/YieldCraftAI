from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from app.schemas.crop import (
    CropRecommendationRequest,
    CropRecommendationResponse,
    CropCandidateResponse,
    CropGuidance
)
from app.core.security import get_current_user_id
from app.ml.model_registry import model_registry
from app.integrations.gemini import gemini_integration
from app.services.farm_service import farm_service

router = APIRouter(prefix="/crops", tags=["Crop Recommendation"])

CROP_SEASON_MAP = {
    "rice": ("Kharif (Monsoon)", "High (1200-1400mm)"),
    "maize": ("Kharif / Rabi", "Moderate (500-700mm)"),
    "chickpea": ("Rabi (Winter)", "Low to Moderate (350-450mm)"),
    "kidneybeans": ("Kharif", "Moderate (500-600mm)"),
    "pigeonpeas": ("Kharif", "Moderate (600-750mm)"),
    "mothbeans": ("Kharif (Arid)", "Low (200-350mm)"),
    "mungbean": ("Kharif / Zaid (Summer)", "Low to Moderate (350-450mm)"),
    "blackgram": ("Kharif", "Moderate (400-500mm)"),
    "lentil": ("Rabi", "Low (300-400mm)"),
    "pomegranate": ("Whole Year (Ambe/Mrig/Hasta)", "Moderate (500-700mm)"),
    "banana": ("Perennial", "High (1500-2000mm)"),
    "mango": ("Summer", "Moderate (700-1000mm)"),
    "grapes": ("Rabi / Spring", "Moderate (500-700mm)"),
    "watermelon": ("Zaid (Summer)", "Moderate (400-600mm)"),
    "muskmelon": ("Zaid (Summer)", "Moderate (400-500mm)"),
    "apple": ("Temperate / Autumn", "Moderate (800-1000mm)"),
    "orange": ("Ambe / Mrig Bahar", "Moderate (750-1000mm)"),
    "papaya": ("Whole Year", "Moderate to High (1000-1200mm)"),
    "coconut": ("Coastal Perennial", "High (1300-2000mm)"),
    "cotton": ("Kharif", "Moderate (700-1100mm)"),
    "jute": ("Pre-Kharif / Monsoon", "High (1200-1500mm)"),
    "coffee": ("Post-Monsoon", "High (1500-2500mm)")
}

@router.post("/recommend", response_model=CropRecommendationResponse)
def recommend_crops(
    req: CropRecommendationRequest,
    enrich_with_gemini: bool = Query(True, description="Enrich top candidate with Gemini AI agronomy"),
    user_id: str = Depends(get_current_user_id)
):
    farm_context = {}
    if req.farm_id:
        try:
            farm = farm_service.get_farm(user_id, req.farm_id)
            farm_context = {
                "farm_name": farm.farm_name,
                "state": farm.state,
                "district": farm.district,
                "soil_type": farm.soil_type
            }
        except Exception:
            pass

    candidates_raw = model_registry.predict_crop(
        nitrogen=req.nitrogen,
        phosphorus=req.phosphorus,
        potassium=req.potassium,
        temperature=req.temperature,
        humidity=req.humidity,
        ph=req.ph,
        rainfall=req.rainfall,
        top_n=req.top_n
    )

    candidate_objs = []
    for c in candidates_raw:
        crop_key = c["crop_name"].lower()
        season_info, water_info = CROP_SEASON_MAP.get(
            crop_key,
            ("Kharif / Rabi", "Moderate (500-800mm)")
        )

        guidance = None
        # Enrich the #1 top candidate or all if requested
        if enrich_with_gemini and c["rank"] == 1:
            try:
                guidance_dict = gemini_integration.explain_crop(c["crop_name"], farm_context)
                guidance = CropGuidance(**guidance_dict)
            except Exception:
                guidance = None

        candidate_objs.append(CropCandidateResponse(
            rank=c["rank"],
            crop_name=c["crop_name"].capitalize(),
            probability=c["probability"],
            confidence_percentage=c["confidence_percentage"],
            season=season_info,
            indicative_water_need=water_info,
            suitability_summary=f"Favorable fit based on soil NPK ({req.nitrogen}-{req.phosphorus}-{req.potassium}) and rainfall ({req.rainfall:.0f}mm).",
            guidance=guidance
        ))

    return CropRecommendationResponse(
        candidates=candidate_objs,
        model_version="CatBoost-CropRec-v1.0 (Accuracy 99.55%)",
        input_snapshot={
            "N": req.nitrogen,
            "P": req.phosphorus,
            "K": req.potassium,
            "temperature": req.temperature,
            "humidity": req.humidity,
            "ph": req.ph,
            "rainfall": req.rainfall
        },
        ranking_method="Authentic multi-class CatBoost probability distribution",
        timestamp=datetime.utcnow().isoformat() + "Z"
    )

@router.get("/explain/{crop_name}", response_model=CropGuidance)
def explain_specific_crop(
    crop_name: str,
    farm_id: Optional[str] = None,
    user_id: str = Depends(get_current_user_id)
):
    farm_context = {}
    if farm_id:
        try:
            farm = farm_service.get_farm(user_id, farm_id)
            farm_context = {
                "farm_name": farm.farm_name,
                "state": farm.state,
                "district": farm.district,
                "soil_type": farm.soil_type
            }
        except Exception:
            pass
    guidance_dict = gemini_integration.explain_crop(crop_name, farm_context)
    return CropGuidance(**guidance_dict)
