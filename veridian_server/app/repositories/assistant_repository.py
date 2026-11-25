from app.config import db


async def find_profile(user_id: str) -> dict | None:
    return await db.assistant_profiles.find_one({"userId": user_id})


async def save_profile(user_id: str, fields: dict) -> None:
    await db.assistant_profiles.update_one({"userId": user_id}, {"$set": fields}, upsert=True)
