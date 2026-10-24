from fastapi import APIRouter, Query
from app.schemas.weather import WeatherResponse
from app.integrations.weather_provider import weather_provider

router = APIRouter(prefix="/weather", tags=["Weather Integration"])

@router.get("", response_model=WeatherResponse)
async def get_weather(
    latitude: float = Query(..., ge=-90.0, le=90.0, description="Latitude"),
    longitude: float = Query(..., ge=-180.0, le=180.0, description="Longitude")
):
    return await weather_provider.get_weather(latitude, longitude)
