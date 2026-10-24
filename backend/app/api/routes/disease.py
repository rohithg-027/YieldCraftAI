from datetime import datetime
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import Optional
import base64
from app.schemas.disease import DiseaseAnalysisRequest, DiseaseAnalysisResponse
from app.core.security import get_current_user_id
from app.integrations.gemini import gemini_integration
from app.services.farm_service import farm_service

router = APIRouter(prefix="/disease", tags=["Disease Detection"])

@router.post("/analyze", response_model=DiseaseAnalysisResponse)
def analyze_disease(
    req: DiseaseAnalysisRequest,
    user_id: str = Depends(get_current_user_id)
):
    analysis_dict = gemini_integration.analyze_disease(
        image_base64=req.image_base64,
        crop=req.crop,
        plant_part=req.plant_part,
        symptoms=req.symptoms_observed
    )

    now = datetime.utcnow().isoformat() + "Z"
    response = DiseaseAnalysisResponse(
        crop_identified=analysis_dict.get("crop_identified", req.crop or "Plant"),
        condition_detected=analysis_dict.get("condition_detected", "Foliar Condition"),
        is_healthy=bool(analysis_dict.get("is_healthy", False)),
        confidence_level=analysis_dict.get("confidence_level", "Moderate"),
        visible_symptoms=analysis_dict.get("visible_symptoms", ["Leaf discoloration"]),
        possible_causes=analysis_dict.get("possible_causes", ["Environmental / Pathogen"]),
        treatment_plan=analysis_dict.get("treatment_plan", ["Prune damaged foliage"]),
        prevention_measures=analysis_dict.get("prevention_measures", ["Avoid overhead watering"]),
        severity=analysis_dict.get("severity", "Moderate"),
        expert_advice=analysis_dict.get("expert_advice", "Consult local agricultural extension center if condition spreads."),
        model_provider="Google Gemini Multimodal AI & YieldCraft Plant Pathology Engine",
        analysis_date=now
    )

    if req.farm_id:
        try:
            # Store in digital diary against farm
            farm_service.add_diary_entry(user_id, req.farm_id, {
                "category": "disease_check",
                "condition": response.condition_detected,
                "crop": response.crop_identified,
                "severity": response.severity,
                "summary": f"{response.condition_detected} detected with {response.severity} severity."
            })
        except Exception:
            pass

    return response

@router.post("/upload", response_model=DiseaseAnalysisResponse)
async def upload_and_analyze_image(
    file: UploadFile = File(...),
    farm_id: Optional[str] = Form(None),
    crop: Optional[str] = Form(None),
    plant_part: str = Form("Leaves"),
    symptoms: Optional[str] = Form(None),
    user_id: str = Depends(get_current_user_id)
):
    # Validate content type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image (JPEG/PNG/WEBP).")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:  # 10 MB limit
        raise HTTPException(status_code=400, detail="Image size exceeds 10 MB limit.")

    b64_str = base64.b64encode(contents).decode("utf-8")
    req = DiseaseAnalysisRequest(
        farm_id=farm_id,
        crop=crop,
        plant_part=plant_part,
        symptoms_observed=symptoms,
        image_base64=b64_str
    )
    return analyze_disease(req=req, user_id=user_id)
