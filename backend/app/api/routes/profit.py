from fastapi import APIRouter, Depends
from app.schemas.profit import (
    ProfitEstimationRequest,
    ProfitEstimationResponse
)
from app.core.security import get_current_user_id
from app.services.profit_service import profit_service

router = APIRouter(prefix="/profit", tags=["Profit Optimization"])

@router.post("/estimate", response_model=ProfitEstimationResponse)
def estimate_profit(
    req: ProfitEstimationRequest,
    user_id: str = Depends(get_current_user_id)
):
    return profit_service.calculate_profit(req)
