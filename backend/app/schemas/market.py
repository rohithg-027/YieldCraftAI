from typing import List, Optional
from pydantic import BaseModel, Field

class MarketPriceRecord(BaseModel):
    state: str
    district: str
    market: str
    commodity: str
    variety: str
    arrival_date: str
    min_price: float
    max_price: float
    modal_price: float
    price_unit: str = "Rs/Quintal"
    source: str = "Government of India data.gov.in (Agmarknet Mandi)"
    retrieved_at: str

class MarketPriceResponse(BaseModel):
    total_records: int
    data_freshness: str
    source_attribution: str = "Ministry of Agriculture and Farmers Welfare / data.gov.in (Resource ID: 9ef84268-d588-465a-a308-a864a43d0070)"
    records: List[MarketPriceRecord]
