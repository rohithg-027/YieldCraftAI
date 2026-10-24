from typing import List
from fastapi import APIRouter, Depends, status
from app.schemas.farm import FarmCreateRequest, FarmUpdateRequest, FarmResponse
from app.core.security import get_current_user_id
from app.services.farm_service import farm_service

router = APIRouter(prefix="/farms", tags=["Farms"])

@router.post("", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
def create_farm(req: FarmCreateRequest, user_id: str = Depends(get_current_user_id)):
    return farm_service.create_farm(owner_uid=user_id, req=req)

@router.get("", response_model=List[FarmResponse])
def list_farms(user_id: str = Depends(get_current_user_id)):
    return farm_service.list_farms_for_user(owner_uid=user_id)

@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm(farm_id: str, user_id: str = Depends(get_current_user_id)):
    return farm_service.get_farm(owner_uid=user_id, farm_id=farm_id)

@router.patch("/{farm_id}", response_model=FarmResponse)
def update_farm(farm_id: str, req: FarmUpdateRequest, user_id: str = Depends(get_current_user_id)):
    return farm_service.update_farm(owner_uid=user_id, farm_id=farm_id, req=req)

@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farm(farm_id: str, user_id: str = Depends(get_current_user_id)):
    farm_service.delete_farm(owner_uid=user_id, farm_id=farm_id)
    return None
