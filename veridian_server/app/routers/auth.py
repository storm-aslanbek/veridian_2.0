import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException, Body, Depends
from app.config import db
from app.security import get_password_hash, verify_password, create_access_token
from app.models.user import UserCreate, Token, UserResponse

router = APIRouter()

def now_iso():
    return datetime.now().isoformat()

def generate_id():
    return str(uuid.uuid4())

async def seed_user_data(user_id: str, user_name: str):
    acc1_id = generate_id()
    accounts = [
        {
            "id": acc1_id,
            "userId": user_id,
            "accountNumber": "KZ44 1234 5678 9000",
            "accountName": "Основной счет",
            "accountType": "Checking",
            "balance": 150000.0,
            "currency": "KZT",
            "isActive": True,
            "createdAt": now_iso(),
            "updatedAt": now_iso()
        }
    ]
    await db.accounts.insert_many(accounts)
    card = {
        "id": generate_id(),
        "userId": user_id,
        "accountId": acc1_id,
        "cardNumber": "4400 1122 3344 5566",
        "cardHolderName": user_name.upper(),
        "expiryDate": "12/28",
        "cvv": "123",
        "cardType": "Visa",
        "status": "active",
        "cardColor": "0xFF1E1E1E",
        "createdAt": now_iso(),
        "updatedAt": now_iso()
    }
    await db.cards.insert_one(card)

@router.post("/auth/register", response_model=Token)
async def register(user_data: UserCreate):
    if await db.users.find_one({"phone": user_data.phone}):
        raise HTTPException(status_code=400, detail="Phone already registered")
    if await db.users.find_one({"iin": user_data.iin}):
        raise HTTPException(status_code=400, detail="IIN already registered")

    user_id = generate_id()
    now = now_iso()
    new_user = {
        "id": user_id,
        "firstName": user_data.firstName,
        "surname": user_data.surname,
        "patronymic": user_data.patronymic,
        "iin": user_data.iin,
        "phone": user_data.phone,
        "avatarUrl": None,
        "hashed_password": get_password_hash(user_data.password),
        "createdAt": now,
        "updatedAt": now
    }
    await db.users.insert_one(new_user)
    full_name = f"{user_data.firstName} {user_data.surname}"
    await seed_user_data(user_id, full_name)
    token = create_access_token(data={"sub": new_user["phone"]})
    return {"token": token, "user": UserResponse(**new_user)}

@router.post("/auth/login")
async def login(data: dict = Body(...)):
    phone = data.get("phone")
    password = data.get("password")
    user = await db.users.find_one({"phone": phone})
    if not user or not verify_password(password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(data={"sub": user["phone"]})
    return {"token": token, "user": UserResponse(**user)}