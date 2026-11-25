from app.config import db


async def mark_history_seeded(user_id: str) -> bool:
    result = await db.users.update_one(
        {"id": user_id, "paymentsSeeded": {"$ne": True}},
        {"$set": {"paymentsSeeded": True}},
    )
    return result.modified_count == 1


async def insert_many(payments: list[dict]) -> None:
    await db.payments.insert_many(payments)


async def insert_one(payment: dict) -> None:
    await db.payments.insert_one(payment)


async def find_by_user(user_id: str) -> list[dict]:
    cursor = db.payments.find({"userId": user_id}).sort("date", -1)
    return await cursor.to_list(1000)


async def find_since(user_id: str, since: str) -> list[dict]:
    cursor = db.payments.find({"userId": user_id, "date": {"$gte": since}})
    return await cursor.to_list(None)


async def count_unread(user_id: str) -> int:
    return await db.payments.count_documents({"userId": user_id, "isRead": False})


async def mark_all_read(user_id: str) -> None:
    await db.payments.update_many({"userId": user_id, "isRead": False}, {"$set": {"isRead": True}})


async def debit_account(account_id: str, user_id: str, amount: float) -> dict | None:
    return await db.accounts.find_one_and_update(
        {"id": account_id, "userId": user_id, "balance": {"$gte": amount}},
        {"$inc": {"balance": -amount}},
    )


async def insert_transaction(transaction: dict) -> None:
    await db.transactions.insert_one(transaction)
