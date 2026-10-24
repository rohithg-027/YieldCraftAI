from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class FarmCreateRequest(BaseModel):
    farm_name: str = Field(..., min_length=2, max_length=100)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    location_accuracy_meters: Optional[float] = Field(None, ge=0.0)
    address: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: str = Field(..., min_length=2)
    country: str = "India"
    area: float = Field(..., gt=0.0)
    area_unit: str = Field("hectares", description="hectares or acres")
    soil_type: str = Field("Loamy", description="Sandy, Loamy, Clay, Black, Red, Laterite, Alluvial")
    irrigation_source: Optional[str] = Field("Borewell", description="Borewell, Canal, Rainfed, Well, River")
    active_crop: Optional[str] = None

class FarmUpdateRequest(BaseModel):
    farm_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    area: Optional[float] = None
    area_unit: Optional[str] = None
    soil_type: Optional[str] = None
    irrigation_source: Optional[str] = None
    active_crop: Optional[str] = None
    address: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None

class FarmResponse(BaseModel):
    farm_id: str
    owner_uid: str
    farm_name: str
    latitude: float
    longitude: float
    location_accuracy_meters: Optional[float] = None
    address: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: str
    country: str = "India"
    area: float
    area_unit: str
    soil_type: str
    irrigation_source: Optional[str] = None
    active_crop: Optional[str] = None
    created_at: str
    updated_at: str
