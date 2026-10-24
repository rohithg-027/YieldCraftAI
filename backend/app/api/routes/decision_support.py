from fastapi import APIRouter, Depends
from app.schemas.decision_support import DecisionSupportSummary
from app.core.security import get_current_user_id
from app.services.decision_support_service import decision_support_service

router = APIRouter(prefix="/farms/{farm_id}/decision-support", tags=["Unified Decision Support"])

@router.get("", response_model=DecisionSupportSummary)
async def get_decision_support(
    farm_id: str,
    user_id: str = Depends(get_current_user_id)
):
    return await decision_support_service.get_summary(owner_uid=user_id, farm_id=farm_id)
