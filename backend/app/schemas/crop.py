from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class CropRecommendationRequest(BaseModel):
    farm_id: Optional[str] = None
    nitrogen: float = Field(..., ge=0.0, le=300.0, description="Nitrogen ratio N")
    phosphorus: float = Field(..., ge=0.0, le=300.0, description="Phosphorus ratio P")
    potassium: float = Field(..., ge=0.0, le=300.0, description="Potassium ratio K")
    temperature: float = Field(..., ge=-10.0, le=60.0, description="Temperature in Celsius")
    humidity: float = Field(..., ge=0.0, le=100.0, description="Relative humidity %")
    ph: float = Field(..., ge=0.0, le=14.0, description="Soil pH value")
    rainfall: float = Field(..., ge=0.0, le=1000.0, description="Rainfall in mm")
    top_n: int = Field(5, ge=1, le=10, description="Number of candidate crops to return")

class CropGuidance(BaseModel):
    crop_overview: Optional[str] = None
    why_recommended: Optional[str] = None
    soil_suitability: Optional[str] = None
    climate_suitability: Optional[str] = None
    sowing_season: Optional[str] = None
    crop_duration: Optional[str] = None
    water_management: Optional[str] = None
    nutrient_management: Optional[str] = None
    major_risks: Optional[str] = None
    harvesting_considerations: Optional[str] = None
    market_potential: Optional[str] = None

class CropCandidateResponse(BaseModel):
    rank: int
    crop_name: str
    probability: float
    confidence_percentage: float
    season: str
    indicative_water_need: str
    suitability_summary: str
    guidance: Optional[CropGuidance] = None

class CropRecommendationResponse(BaseModel):
    candidates: List[CropCandidateResponse]
    model_version: str = "CatBoost-CropRec-v1.0"
    input_snapshot: Dict[str, float]
    ranking_method: str = "Multi-class model predicted probability distribution"
    timestamp: str
