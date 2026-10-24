from datetime import datetime
from fastapi import APIRouter, Depends
from app.schemas.fertilizer import (
    FertilizerRecommendationRequest,
    FertilizerRecommendationResponse
)
from app.core.security import get_current_user_id
from app.ml.model_registry import model_registry

router = APIRouter(prefix="/fertilizer", tags=["Fertilizer Recommendation"])

FERTILIZER_GUIDANCE = {
    "Urea": (
        "Apply Urea (46% N) in 2 to 3 split doses: 1/3 at basal, 1/3 at active tillering/vegetative, and 1/3 at panicle/booting stage. Avoid application immediately before heavy rainfall.",
        "Excessive nitrogen leads to vegetative overgrowth, crop lodging, and increased susceptibility to insect pests like leaf folders."
    ),
    "DAP": (
        "Apply Di-Ammonium Phosphate (18-46-0) as a basal placement close to the root zone at sowing or transplanting. Ensures strong seedling root establishment.",
        "Do not mix DAP directly with alkaline amendments like unslaked lime, as volatile ammonia loss may occur."
    ),
    "MOP": (
        "Muriate of Potash (60% K2O) strengthens cell walls, improves disease resistance, and aids grain/fruit filling. Apply half at basal and half during fruit/grain development.",
        "Avoid heavy MOP in chloride-sensitive crops like tobacco; however, highly beneficial for cereals, sugarcane, and oilseeds."
    ),
    "SOP": (
        "Sulphate of Potash (50% K2O, 17% S) provides chloride-free potassium and essential sulfur. Excellent for high-value horticultural crops and fruits.",
        "Ensure uniform field dispersion to prevent localized salt concentration."
    ),
    "NPK 12-32-16": (
        "High-phosphorus complex fertilizer ideal for basal soil application. Promotes early root vigor and vigorous vegetative development.",
        "Store in a dry location to avoid caking; apply 4-5 cm below seed level."
    ),
    "NPK 17-17-17": (
        "Balanced grade fertilizer supplying equal parts N, P, and K. Suitable for crops entering active vegetative and flowering initiation.",
        "Incorporate into soil followed by light irrigation for uniform nutrient absorption."
    ),
    "NPK 20-20-20": (
        "100% water-soluble balanced nutrient formula, highly effective for fertigation and critical fruiting development.",
        "Do not spray during peak midday heat; prefer early morning or late afternoon."
    ),
    "Neem Coated Urea": (
        "Slow-release nitrogen fertilizer. Neem oil coating inhibits nitrification, minimizing leaching and volatilization while boosting nitrogen use efficiency by 10-15%.",
        "Keep split applications synchronized with crop growth stages."
    ),
    "Borax": (
        "Micronutrient source providing 10.5-11% elemental Boron. Crucial for flower pollination, pollen tube growth, and preventing fruit cracking in alkaline soils.",
        "Boron margin of safety is narrow; never exceed recommended dosage (typically 5-10 kg/ha soil or 0.1-0.2% foliar spray)."
    ),
    "Compost": (
        "Well-decomposed organic matter that enriches soil microbial life, enhances cation exchange capacity (CEC), and improves moisture retention.",
        "Ensure compost is thoroughly matured without un-decomposed weed seeds or pathogens."
    )
}

@router.post("/recommend", response_model=FertilizerRecommendationResponse)
def recommend_fertilizer(
    req: FertilizerRecommendationRequest,
    user_id: str = Depends(get_current_user_id)
):
    result = model_registry.predict_fertilizer(
        temperature=req.temperature,
        humidity=req.humidity,
        rainfall=req.rainfall,
        moisture=req.moisture,
        soil_type=req.soil_type,
        soil_ph=req.soil_ph,
        nitrogen=req.nitrogen,
        phosphorus=req.phosphorus,
        potassium=req.potassium,
        crop_type=req.crop_type,
        growth_stage=req.growth_stage
    )

    fert_name = result["fertilizer_name"]
    guidance, cautions = FERTILIZER_GUIDANCE.get(
        fert_name,
        (
            f"Apply {fert_name} according to package agronomic directions for {req.crop_type}.",
            "Maintain balanced fertilization and conduct regular soil testing."
        )
    )

    return FertilizerRecommendationResponse(
        fertilizer_name=fert_name,
        confidence=result["confidence"],
        crop_type=req.crop_type,
        growth_stage=req.growth_stage,
        soil_context={
            "soil_type": req.soil_type,
            "soil_ph": req.soil_ph,
            "moisture_pct": req.moisture,
            "nitrogen": req.nitrogen,
            "phosphorus": req.phosphorus,
            "potassium": req.potassium
        },
        application_guidance=guidance,
        safety_cautions=cautions,
        model_version="CatBoost-Pipeline-Fertilizer-v2.0 (F1 ~0.99)",
        timestamp=datetime.utcnow().isoformat() + "Z"
    )
