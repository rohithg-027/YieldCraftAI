from typing import Optional, List
from pydantic import BaseModel, Field

class DiseaseAnalysisRequest(BaseModel):
    farm_id: Optional[str] = None
    crop: Optional[str] = Field(None, description="Reported crop name")
    plant_part: str = Field("Leaves", description="Leaves, Stem, Fruit, Flower, Root")
    symptoms_observed: Optional[str] = Field(None, description="User observed symptoms")
    image_base64: str = Field(..., description="Base64 encoded plant image")

class DiseaseAnalysisResponse(BaseModel):
    crop_identified: str
    condition_detected: str
    is_healthy: bool
    confidence_level: str
    visible_symptoms: List[str]
    possible_causes: List[str]
    treatment_plan: List[str]
    prevention_measures: List[str]
    severity: str
    expert_advice: str
    model_provider: str = "Google Gemini Multimodal Vision (Primary) & YieldCraft Ag Diagnostic Engine"
    analysis_date: str
