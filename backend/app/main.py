import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.ml.model_registry import model_registry

from app.api.routes.auth import router as auth_router
from app.api.routes.farms import router as farms_router
from app.api.routes.soil import router as soil_router
from app.api.routes.crop import router as crop_router
from app.api.routes.fertilizer import router as fertilizer_router
from app.api.routes.yield_prediction import router as yield_router
from app.api.routes.irrigation import router as irrigation_router
from app.api.routes.disease import router as disease_router
from app.api.routes.market import router as market_router
from app.api.routes.weather import router as weather_router
from app.api.routes.profit import router as profit_router
from app.api.routes.assistant import router as assistant_router
from app.api.routes.sensors import router as sensors_router
from app.api.routes.decision_support import router as decision_support_router
from app.api.routes.diary import router as diary_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("yieldcraft.main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing YieldCraft AI backend services...")
    # Load all 4 verified machine learning models into memory
    model_registry.load_models()
    logger.info("Machine learning registry initialization complete.")
    yield
    logger.info("YieldCraft AI backend shutdown complete.")

app = FastAPI(
    title="YieldCraft AI Backend API",
    description="Smart Crop Planning, Prediction and Profit Optimization Platform",
    version="1.0.0",
    lifespan=lifespan
)

# CORS Middleware
origins = settings.ALLOWED_ORIGINS
if "*" in origins or not origins:
    allow_origins = ["*"]
else:
    allow_origins = origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers with /api/v1 prefix
api_v1_prefix = "/api/v1"
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(farms_router, prefix=api_v1_prefix)
app.include_router(soil_router, prefix=api_v1_prefix)
app.include_router(crop_router, prefix=api_v1_prefix)
app.include_router(fertilizer_router, prefix=api_v1_prefix)
app.include_router(yield_router, prefix=api_v1_prefix)
app.include_router(irrigation_router, prefix=api_v1_prefix)
app.include_router(disease_router, prefix=api_v1_prefix)
app.include_router(market_router, prefix=api_v1_prefix)
app.include_router(weather_router, prefix=api_v1_prefix)
app.include_router(profit_router, prefix=api_v1_prefix)
app.include_router(assistant_router, prefix=api_v1_prefix)
app.include_router(sensors_router, prefix=api_v1_prefix)
app.include_router(decision_support_router, prefix=api_v1_prefix)
app.include_router(diary_router, prefix=api_v1_prefix)

@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": "YieldCraft AI Engine",
        "version": "1.0.0",
        "models_loaded": {
            "crop_recommendation": model_registry.crop_model is not None,
            "fertilizer_recommendation": model_registry.fertilizer_model is not None,
            "yield_prediction": model_registry.yield_model is not None,
            "irrigation_recommendation": model_registry.irrigation_model is not None
        }
    }

@app.get("/", tags=["Root"])
def root():
    return {
        "name": "YieldCraft AI — Smart Crop Planning, Prediction and Profit Optimization Platform",
        "docs_url": "/docs",
        "health_check": "/health"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.API_HOST, port=settings.API_PORT, reload=True)
