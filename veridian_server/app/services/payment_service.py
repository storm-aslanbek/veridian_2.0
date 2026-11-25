import uuid
from datetime import datetime

from fastapi import HTTPException

from app.catalog.brands import BRANDS_BY_CATEGORY, CATEGORY_BY_BRAND
from app.catalog.history import build_history
from app.clock import now_local
from app.repositories import payment_repository as repository

PURCHASE = "purchase"
TRANSFER_OUT = "transfer_out"
TRANSFER_IN = "transfer_in"
SALARY = "salary"

CATEGORY_BY_TYPE = {
    TRANSFER_OUT: "transfer",
    TRANSFER_IN: "transfer",
    SALARY: "salary",
}


def _new_id() -> str:
    return str(uuid.uuid4())


def _category(message_type: str, brand: str | None) -> str:
    if message_type == PURCHASE:
        return CATEGORY_BY_BRAND.get(brand, "services")
    return CATEGORY_BY_TYPE[message_type]


def short_name(first_name: str, surname: str) -> str:
    return f"{first_name} {surname[:1]}." if surname else first_name


def _to_response(message: dict) -> dict:
    message_type = message.get("type", PURCHASE)
    brand = message.get("brand")
    return {
        **message,
        "type": message_type,
        "counterparty": message.get("counterparty") or brand or "",
        "category": _category(message_type, brand),
    }


async def ensure_history(user_id: str) -> None:
    if not await repository.mark_history_seeded(user_id):
        return
    history = [
        {"id": _new_id(), "userId": user_id, "isRead": True, **message}
        for message in build_history(BRANDS_BY_CATEGORY)
    ]
    await repository.insert_many(history)


async def list_payments(user_id: str) -> list[dict]:
    await ensure_history(user_id)
    return [_to_response(message) for message in await repository.find_by_user(user_id)]


async def list_since(user_id: str, since: datetime) -> list[dict]:
    await ensure_history(user_id)
    messages = await repository.find_since(user_id, since.isoformat())
    return [_to_response(message) for message in messages]


async def count_unread(user_id: str) -> int:
    await ensure_history(user_id)
    return await repository.count_unread(user_id)


async def mark_all_read(user_id: str) -> None:
    await repository.mark_all_read(user_id)


async def record_message(user_id: str, message_type: str, counterparty: str, price: float) -> dict:
    await ensure_history(user_id)
    message = {
        "id": _new_id(),
        "userId": user_id,
        "type": message_type,
        "date": now_local().isoformat(),
        "price": price,
        "counterparty": counterparty,
        "isRead": False,
    }
    await repository.insert_one(message)
    return _to_response(message)


async def purchase(user_id: str, account_id: str, brand: str, price: float) -> dict:
    if brand not in CATEGORY_BY_BRAND:
        raise HTTPException(status_code=404, detail="Brand not found")
    await ensure_history(user_id)

    account = await repository.debit_account(account_id, user_id, price)
    if account is None:
        raise HTTPException(status_code=400, detail="Account not found or insufficient funds")

    now = now_local().isoformat()
    message = {
        "id": _new_id(),
        "userId": user_id,
        "type": PURCHASE,
        "date": now,
        "price": price,
        "counterparty": brand,
        "brand": brand,
        "isRead": False,
    }
    await repository.insert_one(message)
    await repository.insert_transaction({
        "id": _new_id(),
        "userId": user_id,
        "accountId": account_id,
        "type": "purchase",
        "category": CATEGORY_BY_BRAND[brand],
        "amount": -price,
        "currency": account["currency"],
        "recipient": brand,
        "description": f"Payment to {brand}",
        "status": "completed",
        "transactionDate": now,
        "createdAt": now,
        "updatedAt": now,
    })
    return _to_response(message)
