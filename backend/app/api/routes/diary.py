from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, status
from app.core.security import get_current_user_id
from app.services.farm_service import farm_service

router = APIRouter(prefix="/farms/{farm_id}/diary", tags=["Digital Farm Diary"])

class DiaryEntryCreateRequest(BaseModel):
    category: str = Field(..., description="'activity', 'observation', 'fertilizer_application', 'irrigation_log', 'disease_check', 'harvest'")
    title: str = Field(..., min_length=2)
    notes: str = Field(..., min_length=1)
    crop: Optional[str] = None
    cost: Optional[float] = Field(0.0, ge=0.0)

@router.post("", status_code=status.HTTP_201_CREATED)
def add_diary_entry(
    farm_id: str,
    req: DiaryEntryCreateRequest,
    user_id: str = Depends(get_current_user_id)
):
    entry_dict = req.model_dump()
    return farm_service.add_diary_entry(owner_uid=user_id, farm_id=farm_id, entry=entry_dict)

@router.get("", response_model=List[Dict[str, Any]])
def list_diary_entries(
    farm_id: str,
    user_id: str = Depends(get_current_user_id)
):
    return farm_service.list_diary_entries(owner_uid=user_id, farm_id=farm_id)
