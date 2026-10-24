from typing import Optional
from fastapi import APIRouter, Query
from app.schemas.market import MarketPriceResponse
from app.integrations.market_provider import market_provider

router = APIRouter(prefix="/market", tags=["Market Intelligence"])

@router.get("/prices", response_model=MarketPriceResponse)
async def get_market_prices(
    commodity: Optional[str] = Query(None, description="Commodity name, e.g. Rice, Wheat, Pomegranate"),
    state: Optional[str] = Query(None, description="State, e.g. Karnataka, Maharashtra, Punjab"),
    district: Optional[str] = Query(None, description="District name"),
    market: Optional[str] = Query(None, description="Market or Mandi name")
):
    return await market_provider.get_prices(
        commodity=commodity,
        state=state,
        district=district,
        market=market
    )
