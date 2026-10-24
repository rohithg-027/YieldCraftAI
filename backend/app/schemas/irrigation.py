from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

class IrrigationRecommendationRequest(BaseModel):
    farm_id: Optional[str] = None
    soil_type: str = Field("Loamy", description="Sandy, Loamy, Clay, Black, Red, Laterite, Alluvial")
    soil_ph: float = Field(6.5, ge=0.0, le=14.0)
    soil_moisture: float = Field(40.0, ge=0.0, le=100.0)
    organic_carbon: float = Field(0.5, ge=0.0, le=10.0)
    electrical_conductivity: float = Field(1.0, ge=0.0, le=20.0)
    temperature_c: float = Field(28.0, ge=-10.0, le=60.0)
    humidity: float = Field(65.0, ge=0.0, le=100.0)
    rainfall_mm: float = Field(10.0, ge=0.0, le=500.0)
    sunlight_hours: float = Field(7.0, ge=0.0, le=16.0)
    wind_speed_kmh: float = Field(12.0, ge=0.0, le=150.0)
    crop_type: str = Field("Rice", description="Crop name")
    crop_growth_stage: str = Field("Vegetative", description="Seedling, Vegetative, Flowering, Fruiting, Harvest")
    season: str = Field("Kharif", description="Kharif, Rabi, Summer, Whole Year")
    irrigation_type: str = Field("Drip", description="Drip, Sprinkler, Flood, Furrow")
    water_source: str = Field("Borewell", description="Borewell, Canal, Well, River, Rainfed")
    field_area_hectare: float = Field(1.0, gt=0.0)
    mulching_used: str = Field("No", description="Yes or No")
    previous_irrigation_mm: float = Field(15.0, ge=0.0)
    region: str = Field("South", description="North, South, East, West, Central")

class IrrigationRecommendationResponse(BaseModel):
    irrigation_need: str = Field(..., description="High, Medium, or Low")
    probabilities: Dict[str, float]
    soil_moisture: float
    rainfall_context: float
    recommended_action: str
    water_conservation_tip: str
    model_version: str = "CatBoost-Irrigation-Pipeline-v1.0"
    timestamp: str
