from fastapi import APIRouter, Depends, HTTPException
from app.config import db
from app.security import get_current_user
from app.models.user import UserResponse, UserSearchRequest

router = APIRouter()


@router.get("/users/me", response_model=UserResponse)
async def read_users_me(current_user: UserResponse = Depends(get_current_user)):
    return current_user


@router.post("/users/search")
async def search_user_by_phone(req: UserSearchRequest, current_user: UserResponse = Depends(get_current_user)):
    clean_phone = "".join(filter(str.isdigit, req.phone))
    search_phone = clean_phone
    if len(clean_phone) == 11 and clean_phone.startswith('8'):
        search_phone = '7' + clean_phone[1:]
    elif len(clean_phone) == 10:
        search_phone = '7' + clean_phone

    user = await db.users.find_one({"phone": search_phone})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user["id"] == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot transfer to yourself")
    return {
        "firstName": user["firstName"],
        "surname": user["surname"],
        "patronymic": user.get("patronymic")
    }