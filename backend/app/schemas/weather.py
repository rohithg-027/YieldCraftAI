from typing import Optional, List
from pydantic import BaseModel, Field

class DailyForecast(BaseModel):
    date: str
    max_temp_c: float
    min_temp_c: float
    precipitation_sum_mm: float
    weather_condition: str

class WeatherResponse(BaseModel):
    latitude: float
    longitude: float
    temperature_c: float
    relative_humidity_pct: float
    precipitation_mm: float
    wind_speed_kmh: float
    weather_condition: str
    is_day: bool
    forecast: List[DailyForecast]
    annual_rainfall_mm: float = 950.0
    source: str = "Open-Meteo & IMD Agrometeorological Service"
    retrieved_at: str

