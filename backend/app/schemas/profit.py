from typing import Optional, Dict
from pydantic import BaseModel, Field

class ExpenseBreakdown(BaseModel):
    seeds: float = Field(0.0, ge=0.0)
    fertilizer: float = Field(0.0, ge=0.0)
    crop_protection: float = Field(0.0, ge=0.0)
    irrigation: float = Field(0.0, ge=0.0)
    labour: float = Field(0.0, ge=0.0)
    machinery: float = Field(0.0, ge=0.0)
    transport: float = Field(0.0, ge=0.0)
    miscellaneous: float = Field(0.0, ge=0.0)

class ProfitEstimationRequest(BaseModel):
    farm_id: Optional[str] = None
    crop: str
    area_hectares: float = Field(..., gt=0.0)
    predicted_yield_per_hectare: float = Field(..., gt=0.0, description="Yield in Quintals/Hectare")
    market_price_per_quintal: float = Field(..., gt=0.0, description="Mandi price in Rs/Quintal")
    market_name: Optional[str] = "Local Mandi"
    expenses: ExpenseBreakdown

class ScenarioDetail(BaseModel):
    scenario_name: str
    assumed_yield_per_ha: float
    assumed_price_per_quintal: float
    total_production_quintals: float
    gross_revenue: float
    total_expenses: float
    net_profit: float
    profit_margin_pct: float
    description: str

class ProfitEstimationResponse(BaseModel):
    crop: str
    area_hectares: float
    expected_production_quintals: float
    market_price_per_quintal: float
    market_name: str
    total_expenses: float
    base_gross_revenue: float
    base_net_profit: float
    profit_margin_percentage: float
    scenarios: Dict[str, ScenarioDetail]
    disclaimer: str = "Estimates are for planning purposes and do not guarantee market realization."
    calculated_at: str
