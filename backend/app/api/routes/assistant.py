from datetime import datetime
from fastapi import APIRouter, Depends
from app.schemas.assistant import AssistantChatRequest, AssistantChatResponse
from app.core.security import get_current_user_id
from app.integrations.gemini import gemini_integration
from app.services.farm_service import farm_service

router = APIRouter(prefix="/assistant", tags=["AI Farming Assistant"])

@router.post("/chat", response_model=AssistantChatResponse)
def chat_assistant(
    req: AssistantChatRequest,
    user_id: str = Depends(get_current_user_id)
):
    farm_context = req.farm_context or {}
    if req.farm_id and not farm_context:
        try:
            farm = farm_service.get_farm(user_id, req.farm_id)
            latest_soil = farm_service.get_latest_soil_profile(user_id, req.farm_id)
            farm_context = {
                "farm_name": farm.farm_name,
                "state": farm.state,
                "district": farm.district,
                "soil_type": farm.soil_type,
                "area_ha": farm.area,
                "active_crop": farm.active_crop,
                "soil_profile": latest_soil.model_dump() if latest_soil else None
            }
        except Exception:
            pass

    history_dicts = [
        {"role": m.role, "content": m.content}
        for m in (req.conversation_history or [])
    ]

    res = gemini_integration.chat_assistant(
        message=req.message,
        farm_context=farm_context,
        history=history_dicts
    )

    return AssistantChatResponse(
        reply=res["reply"],
        suggested_actions=res.get("suggested_actions", []),
        source_attribution="YieldCraft Agricultural Intelligence Engine & Gemini AI",
        timestamp=datetime.utcnow().isoformat() + "Z"
    )
