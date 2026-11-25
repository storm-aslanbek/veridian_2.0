from fastapi import APIRouter, Depends, HTTPException

from app.models.assistant import (
    AssistantProfile, AssistantSettings, ChatRequest, ChatResponse, CheckRequest, CheckResponse,
)
from app.models.user import UserResponse
from app.security import get_current_user
from app.services import assistant_service
from app.services.assistant_chat_service import AssistantUnavailable

router = APIRouter(prefix="/assistant")


@router.get("/profile", response_model=AssistantProfile)
async def get_profile(current_user: UserResponse = Depends(get_current_user)):
    return await assistant_service.get_profile(current_user.id)


@router.put("/profile", response_model=AssistantProfile)
async def save_profile(settings: AssistantSettings,
                       current_user: UserResponse = Depends(get_current_user)):
    return await assistant_service.save_settings(current_user.id, settings)


@router.get("/summary")
async def get_summary(current_user: UserResponse = Depends(get_current_user)):
    try:
        return await assistant_service.get_summary(current_user.id)
    except assistant_service.SalaryRequired:
        raise HTTPException(status_code=409, detail="salary_required")


@router.post("/check", response_model=CheckResponse)
async def check_operation(request: CheckRequest,
                          current_user: UserResponse = Depends(get_current_user)):
    return {"warnings": await assistant_service.check_operation(current_user.id, request)}


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, current_user: UserResponse = Depends(get_current_user)):
    try:
        return {"reply": await assistant_service.ask(current_user.id, request)}
    except assistant_service.SalaryRequired:
        raise HTTPException(status_code=409, detail="salary_required")
    except AssistantUnavailable:
        raise HTTPException(status_code=503, detail="ai_unavailable")
