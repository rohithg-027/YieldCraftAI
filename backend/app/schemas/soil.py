from typing import Optional
from pydantic import BaseModel, Field

class SoilProfileCreateRequest(BaseModel):
    nitrogen: float = Field(..., ge=0.0, le=500.0, description="Nitrogen (N) kg/ha")
    phosphorus: float = Field(..., ge=0.0, le=500.0, description="Phosphorus (P) kg/ha")
    potassium: float = Field(..., ge=0.0, le=500.0, description="Potassium (K) kg/ha")
    ph: float = Field(..., ge=0.0, le=14.0, description="Soil pH value")
    moisture: Optional[float] = Field(None, ge=0.0, le=100.0, description="Soil moisture percentage")
    soil_temperature: Optional[float] = Field(None, ge=-10.0, le=60.0, description="Soil temperature in °C")
    electrical_conductivity: Optional[float] = Field(None, ge=0.0, description="EC in dS/m")
    organic_carbon: Optional[float] = Field(None, ge=0.0, le=10.0, description="Organic Carbon percentage")
    soil_type: Optional[str] = Field("Loamy", description="Sandy, Loamy, Clay, Black, Red, Laterite, Alluvial")
    test_date: Optional[str] = None
    lab_name: Optional[str] = None
    report_number: Optional[str] = None
    source: str = Field("Manual Lab Entry", description="'Manual Lab Entry', 'IoT Sensor', 'Document OCR'")

class SoilProfileResponse(BaseModel):
    profile_id: str
    farm_id: str
    nitrogen: float
    phosphorus: float
    potassium: float
    ph: float
    moisture: Optional[float] = None
    soil_temperature: Optional[float] = None
    electrical_conductivity: Optional[float] = None
    organic_carbon: Optional[float] = None
    soil_type: str
    test_date: Optional[str] = None
    lab_name: Optional[str] = None
    source: str
    created_at: str
