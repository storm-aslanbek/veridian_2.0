from typing import List

from fastapi import APIRouter, Depends

from app.catalog.brands import BRANDS
from app.models.payments import Brand, Payment, PurchaseRequest
from app.models.user import UserResponse
from app.security import get_current_user
from app.services import payment_service

router = APIRouter()


@router.get("/catalog/brands", response_model=List[Brand])
async def get_brands(current_user: UserResponse = Depends(get_current_user)):
    return BRANDS


@router.get("/notifications", response_model=List[Payment])
async def get_notifications(current_user: UserResponse = Depends(get_current_user)):
    return await payment_service.list_payments(current_user.id)


@router.get("/notifications/unread-count")
async def get_unread_count(current_user: UserResponse = Depends(get_current_user)):
    return {"count": await payment_service.count_unread(current_user.id)}


@router.post("/notifications/read-all")
async def read_all(current_user: UserResponse = Depends(get_current_user)):
    await payment_service.mark_all_read(current_user.id)
    return {"status": "success"}


@router.post("/purchases", response_model=Payment)
async def make_purchase(req: PurchaseRequest, current_user: UserResponse = Depends(get_current_user)):
    return await payment_service.purchase(current_user.id, req.accountId, req.brand, req.price)
