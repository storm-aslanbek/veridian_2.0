from app.config import db


async def find_by_user(user_id: str) -> list[dict]:
    return await db.accounts.find({"userId": user_id}).to_list(100)


async def find_one(user_id: str, account_id: str) -> dict | None:
    return await db.accounts.find_one({"id": account_id, "userId": user_id})
