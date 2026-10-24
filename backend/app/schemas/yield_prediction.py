from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

class YieldPredictionRequest(BaseModel):
    farm_id: Optional[str] = None
    crop: str = Field(..., description="Crop name, e.g. Rice, Wheat, Maize")
    crop_year: int = Field(2024, ge=1990, le=2035)
    season: str = Field("Kharif", description="Kharif, Rabi, Whole Year, Summer, Autumn, Winter")
    state: str = Field("Karnataka", description="Indian state name")
    area: float = Field(..., gt=0.0, description="Cultivated land area")
    area_unit: str = Field("hectares", description="hectares or acres")
    annual_rainfall: float = Field(..., ge=0.0, le=5000.0, description="Annual rainfall in mm")
    fertilizer: float = Field(..., ge=0.0, le=1000.0, description="Fertilizer usage kg/ha")
    pesticide: float = Field(..., ge=0.0, le=200.0, description="Pesticide usage kg/ha")

class YieldFactorImpact(BaseModel):
    factor: str
    impact_pct: str
    status: str
    description: str

class YieldBenchmarkComparison(BaseModel):
    state_average_yield: float
    national_average_yield: float
    performance_vs_state_pct: float
    status: str

class YieldHarvestRange(BaseModel):
    conservative_yield: float
    expected_yield: float
    optimistic_yield: float
    conservative_total: float
    expected_total: float
    optimistic_total: float

class YieldRevenueProjection(BaseModel):
    modal_price_per_quintal: float
    market_name: str
    estimated_gross_revenue: float
    conservative_revenue: float
    optimistic_revenue: float

class YieldPredictionResponse(BaseModel):
    crop: str
    predicted_yield_per_hectare: float
    yield_unit: str = "Quintals/Hectare"
    total_area_hectares: float
    total_estimated_production: float
    production_unit: str = "Quintals"
    model_algorithm: str = "RandomForestRegressor Pipeline (R² = 0.9516, MAE = 20.19)"
    harvest_range: Optional[YieldHarvestRange] = None
    benchmark: Optional[YieldBenchmarkComparison] = None
    revenue_projection: Optional[YieldRevenueProjection] = None
    factor_impacts: List[YieldFactorImpact] = Field(default_factory=list)
    optimizations: List[str] = Field(default_factory=list)
    input_summary: Dict[str, Any]
    limitations: str
    timestamp: str
