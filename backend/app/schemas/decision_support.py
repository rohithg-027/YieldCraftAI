from typing import List, Optional, Dict, Any
from pydantic import BaseModel

class DecisionSupportSummary(BaseModel):
    farm_id: str
    farm_name: str
    location: str
    active_crop: Optional[str] = None
    latest_soil_status: str
    weather_summary: str
    top_recommended_crops: List[str]
    fertilizer_recommendation: Optional[str] = None
    irrigation_need: Optional[str] = None
    recent_disease_check: Optional[str] = None
    market_price_highlight: Optional[str] = None
    yield_estimate_highlight: Optional[str] = None
    profit_estimate_highlight: Optional[str] = None
    key_action_items: List[str]
    missing_data_warnings: List[str]
    generated_at: str
