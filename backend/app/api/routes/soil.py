from typing import List, Optional
from fastapi import APIRouter, Depends, status, HTTPException
from app.schemas.soil import SoilProfileCreateRequest, SoilProfileResponse
from app.core.security import get_current_user_id
from app.services.farm_service import farm_service

router = APIRouter(prefix="/farms/{farm_id}/soil-profiles", tags=["Soil Management"])

@router.post("", response_model=SoilProfileResponse, status_code=status.HTTP_201_CREATED)
def add_soil_profile(
    farm_id: str,
    req: SoilProfileCreateRequest,
    user_id: str = Depends(get_current_user_id)
):
    return farm_service.add_soil_profile(owner_uid=user_id, farm_id=farm_id, req=req)

@router.get("", response_model=List[SoilProfileResponse])
def list_soil_profiles(
    farm_id: str,
    user_id: str = Depends(get_current_user_id)
):
    return farm_service.list_soil_profiles(owner_uid=user_id, farm_id=farm_id)

@router.get("/latest", response_model=Optional[SoilProfileResponse])
def get_latest_soil_profile(
    farm_id: str,
    user_id: str = Depends(get_current_user_id)
):
    profile = farm_service.get_latest_soil_profile(owner_uid=user_id, farm_id=farm_id)
    if not profile:
        raise HTTPException(status_code=404, detail="No soil profile found for this farm")
    return profile
