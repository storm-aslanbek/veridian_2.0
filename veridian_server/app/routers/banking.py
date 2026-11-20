import uuid
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Body
from app.config import db
from app.security import get_current_user
from app.models.user import UserResponse
from app.models.banking import (
    BankAccount, Card, Transaction, Bill, Loan, TransferRecipient,
    TransferRequest, TransferByPhoneRequest
)

router = APIRouter()


def now_iso():
    return datetime.now().isoformat()


def generate_id():
    return str(uuid.uuid4())


# === СЧЕТА ===
@router.get("/accounts", response_model=List[BankAccount])
async def get_accounts(current_user: UserResponse = Depends(get_current_user)):
    return await db.accounts.find({"userId": current_user.id}).to_list(100)


@router.get("/accounts/{account_id}", response_model=BankAccount)
async def get_account_detail(account_id: str, current_user: UserResponse = Depends(get_current_user)):
    account = await db.accounts.find_one({"id": account_id, "userId": current_user.id})
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


# === КАРТЫ ===
@router.get("/cards", response_model=List[Card])
async def get_cards(current_user: UserResponse = Depends(get_current_user)):
    return await db.cards.find({"userId": current_user.id}).to_list(100)


# === ТРАНЗАКЦИИ ===
@router.get("/transactions", response_model=List[Transaction])
async def get_transactions(current_user: UserResponse = Depends(get_current_user)):
    cursor = db.transactions.find({"userId": current_user.id}).sort("transactionDate", -1)
    return await cursor.to_list(100)


# === ПЕРЕВОД НА КАРТУ ===
@router.post("/transfers/card")
async def transfer_to_card(req: TransferRequest, current_user: UserResponse = Depends(get_current_user)):
    account = await db.accounts.find_one({"id": req.accountId, "userId": current_user.id})
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    if account["balance"] < req.amount:
        raise HTTPException(status_code=400, detail="Insufficient funds")

    now = now_iso()
    await db.accounts.update_one(
        {"id": req.accountId},
        {"$inc": {"balance": -req.amount}, "$set": {"updatedAt": now}}
    )
    transaction = {
        "id": generate_id(),
        "userId": current_user.id,
        "accountId": req.accountId,
        "type": "transfer",
        "category": "Transfer",
        "amount": -req.amount,
        "currency": account["currency"],
        "recipient": req.cardNumber,
        "description": req.description or f"Transfer to {req.cardNumber}",
        "status": "completed",
        "transactionDate": now,
        "createdAt": now,
        "updatedAt": now
    }
    await db.transactions.insert_one(transaction)
    return {"status": "success", "transactionId": transaction["id"]}


# === ПЕРЕВОД ПО НОМЕРУ (С ЛОГАМИ) ===
@router.post("/transfers/phone")
async def transfer_by_phone(req: TransferByPhoneRequest, current_user: UserResponse = Depends(get_current_user)):
    print(f"--- TRANSFER DEBUG START ---")
    print(f"Sender: {current_user.phone} (ID: {current_user.id})")
    print(f"Request: AccountID={req.accountId}, Phone={req.phoneNumber}, Amount={req.amount}")

    # 1. Ищем счет отправителя
    source_account = await db.accounts.find_one({"id": req.accountId, "userId": current_user.id})
    if not source_account:
        print(f"ERROR: Source account {req.accountId} not found for user {current_user.id}")
        raise HTTPException(status_code=404, detail="Source account not found")

    if source_account["balance"] < req.amount:
        print(f"ERROR: Insufficient funds. Balance: {source_account['balance']}, Required: {req.amount}")
        raise HTTPException(status_code=400, detail="Insufficient funds")

    # 2. Нормализация номера получателя
    clean_phone = "".join(filter(str.isdigit, req.phoneNumber))
    search_phone = clean_phone
    if len(clean_phone) == 11 and clean_phone.startswith('8'):
        search_phone = '7' + clean_phone[1:]
    elif len(clean_phone) == 10:
        search_phone = '7' + clean_phone

    print(f"Searching for recipient phone: '{search_phone}' (Original: '{req.phoneNumber}')")

    # 3. Ищем получателя
    recipient_user = await db.users.find_one({"phone": search_phone})
    if not recipient_user:
        print(f"ERROR: Recipient user with phone '{search_phone}' NOT FOUND in DB.")
        raise HTTPException(status_code=404, detail=f"User with phone {search_phone} not found")

    print(f"Recipient Found: {recipient_user['firstName']} {recipient_user['surname']} (ID: {recipient_user['id']})")

    if recipient_user["id"] == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot transfer to yourself")

    # 4. Ищем активный счет получателя
    recipient_account = await db.accounts.find_one({"userId": recipient_user["id"], "isActive": True})
    if not recipient_account:
        print(f"ERROR: Recipient {recipient_user['id']} has no active accounts.")
        raise HTTPException(status_code=400, detail="Recipient has no active accounts")

    print(f"Recipient Account Found: {recipient_account['id']}")

    # 5. Выполняем транзакцию
    now = now_iso()

    # Списание
    await db.accounts.update_one(
        {"id": req.accountId},
        {"$inc": {"balance": -req.amount}, "$set": {"updatedAt": now}}
    )
    # Пополнение
    await db.accounts.update_one(
        {"id": recipient_account["id"]},
        {"$inc": {"balance": req.amount}, "$set": {"updatedAt": now}}
    )

    # Запись транзакции (Исходящая)
    transaction_out = {
        "id": generate_id(),
        "userId": current_user.id,
        "accountId": req.accountId,
        "type": "transfer_out",
        "category": "Transfer",
        "amount": -req.amount,
        "currency": source_account["currency"],
        "recipient": f"{recipient_user['firstName']} {recipient_user['surname']}",
        "description": req.description or f"Transfer to {search_phone}",
        "status": "completed",
        "transactionDate": now,
        "createdAt": now,
        "updatedAt": now
    }
    await db.transactions.insert_one(transaction_out)

    # Запись транзакции (Входящая)
    transaction_in = {
        "id": generate_id(),
        "userId": recipient_user["id"],
        "accountId": recipient_account["id"],
        "type": "transfer_in",
        "category": "Transfer",
        "amount": req.amount,
        "currency": recipient_account["currency"],
        "recipient": f"{current_user.firstName} {current_user.surname}",
        "description": "Incoming transfer via phone",
        "status": "completed",
        "transactionDate": now,
        "createdAt": now,
        "updatedAt": now
    }
    await db.transactions.insert_one(transaction_in)

    print("--- TRANSFER SUCCESS ---")
    return {"status": "success", "transactionId": transaction_out["id"]}


# === ОСТАЛЬНЫЕ СПИСКИ ===
@router.get("/bills", response_model=List[Bill])
async def get_bills(current_user: UserResponse = Depends(get_current_user)):
    return await db.bills.find({"userId": current_user.id}).to_list(100)


@router.get("/loans", response_model=List[Loan])
async def get_loans(current_user: UserResponse = Depends(get_current_user)):
    return await db.loans.find({"userId": current_user.id}).to_list(100)


@router.get("/recipients", response_model=List[TransferRecipient])
async def get_recipients(current_user: UserResponse = Depends(get_current_user)):
    return await db.recipients.find({"userId": current_user.id}).to_list(100)


@router.post("/recipients", response_model=TransferRecipient)
async def add_recipient(data: dict = Body(...), current_user: UserResponse = Depends(get_current_user)):
    now = now_iso()
    recipient = {
        "id": generate_id(),
        "userId": current_user.id,
        "name": data.get("name", "Unknown"),
        "accountNumber": data.get("accountNumber", ""),
        "bankName": data.get("bankName", "Other Bank"),
        "recipientType": data.get("recipientType", "external"),
        "isFavorite": data.get("isFavorite", False),
        "createdAt": now,
        "updatedAt": now
    }
    await db.recipients.insert_one(recipient)
    return recipient