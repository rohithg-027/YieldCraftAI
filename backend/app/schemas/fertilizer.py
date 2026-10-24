from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

class FertilizerRecommendationRequest(BaseModel):
    farm_id: Optional[str] = None
    temperature: float = Field(..., ge=-10.0, le=60.0)
    humidity: float = Field(..., ge=0.0, le=100.0)
    rainfall: float = Field(..., ge=0.0, le=1000.0)
    moisture: float = Field(..., ge=0.0, le=100.0, description="Soil moisture %")
    soil_type: str = Field(..., description="Sandy, Loamy, Clay, Black, Red, Laterite, Alluvial")
    soil_ph: float = Field(..., ge=0.0, le=14.0)
    nitrogen: float = Field(..., ge=0.0, le=300.0)
    phosphorus: float = Field(..., ge=0.0, le=300.0, description="Phosphorus (mapped to Phosphorous)")
    potassium: float = Field(..., ge=0.0, le=300.0)
    crop_type: str = Field(..., description="Crop name (e.g. Rice, Maize, Cotton)")
    growth_stage: str = Field("Vegetative", description="Seedling, Vegetative, Flowering, Fruiting, Harvest")

class FertilizerRecommendationResponse(BaseModel):
    fertilizer_name: str
    confidence: Optional[float] = None
    crop_type: str
    growth_stage: str
    soil_context: Dict[str, Any]
    application_guidance: str
    safety_cautions: str
    model_version: str = "CatBoost-Pipeline-Fertilizer-v2.0"
    timestamp: str
