from typing import Optional
from pydantic import BaseModel, Field

class SensorReadingRequest(BaseModel):
    device_id: str = Field(..., min_length=2)
    farm_id: str
    nitrogen: Optional[float] = Field(None, ge=0.0, le=500.0)
    phosphorus: Optional[float] = Field(None, ge=0.0, le=500.0)
    potassium: Optional[float] = Field(None, ge=0.0, le=500.0)
    soil_moisture: Optional[float] = Field(None, ge=0.0, le=100.0)
    soil_temperature: Optional[float] = Field(None, ge=-10.0, le=60.0)
    battery_level_pct: Optional[float] = Field(None, ge=0.0, le=100.0)

class SensorReadingResponse(BaseModel):
    reading_id: str
    device_id: str
    farm_id: str
    status: str
    received_at: str
    summary: str
    recommended_crop: Optional[str] = None
    recommended_fertilizer: Optional[str] = None
    irrigation_need: Optional[str] = None
    advisory_summary: Optional[str] = None
