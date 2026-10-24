from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class ChatMessage(BaseModel):
    role: str = Field("user", description="'user' or 'model'")
    content: str

class AssistantChatRequest(BaseModel):
    message: str = Field(..., min_length=1)
    farm_id: Optional[str] = None
    farm_context: Optional[Dict[str, Any]] = None
    conversation_history: Optional[List[ChatMessage]] = []

class AssistantChatResponse(BaseModel):
    reply: str
    suggested_actions: List[str]
    source_attribution: Optional[str] = "YieldCraft Agricultural Knowledge Base & Gemini AI"
    timestamp: str
