from datetime import datetime, timedelta

from app.catalog.brands import CATEGORY_BY_BRAND
from app.clock import now_local
from app.models.assistant import AssistantProfile, AssistantSettings, ChatRequest, CheckRequest
from app.repositories import account_repository, assistant_repository
from app.services import assistant_calculator as calculator
from app.services import assistant_chat_service, payment_service

HISTORY_DAYS = 90
CURRENCY = "KZT"


class SalaryRequired(Exception):
    pass


async def get_profile(user_id: str) -> AssistantProfile:
    document = await assistant_repository.find_profile(user_id)
    return AssistantProfile(**document) if document else AssistantProfile()


async def save_settings(user_id: str, settings: AssistantSettings) -> AssistantProfile:
    fields = {**settings.model_dump(), "updatedAt": now_local().isoformat()}
    await assistant_repository.save_profile(user_id, fields)
    return await get_profile(user_id)


async def _load_operations(user_id: str, now: datetime) -> list[calculator.Operation]:
    messages = await payment_service.list_since(user_id, now - timedelta(days=HISTORY_DAYS))
    return [
        calculator.Operation(
            type=message["type"],
            date=datetime.fromisoformat(message["date"]),
            price=message["price"],
            category=message["category"],
            brand=message.get("brand"),
        )
        for message in messages
    ]


async def _balance(user_id: str) -> float:
    accounts = await account_repository.find_by_user(user_id)
    return sum(a["balance"] for a in accounts if a["isActive"] and a["currency"] == CURRENCY)


async def get_summary(user_id: str) -> dict:
    profile = await get_profile(user_id)
    if profile.salary is None:
        raise SalaryRequired()
    now = now_local()
    operations = await _load_operations(user_id, now)
    return calculator.build_summary(operations, profile, await _balance(user_id), now)


async def check_operation(user_id: str, request: CheckRequest) -> list[dict]:
    profile = await get_profile(user_id)
    if profile.salary is None:
        return []

    now = now_local()
    operations = await _load_operations(user_id, now)
    warnings = []

    account = await account_repository.find_one(user_id, request.accountId)
    if profile.anomalyAlerts and account and account["currency"] == CURRENCY:
        message_type = calculator.PURCHASE if request.kind == "purchase" else calculator.TRANSFER_OUT
        similar = [o.price for o in operations if o.type == message_type]
        warnings += calculator.anomaly_warnings(
            request.amount, profile.salary, account["balance"], similar)

    category = CATEGORY_BY_BRAND.get(request.brand)
    if request.kind == "purchase" and category:
        warnings += calculator.limit_warnings(
            operations, profile.categoryLimits, category, request.amount, now)
    return warnings


async def ask(user_id: str, request: ChatRequest) -> str:
    summary = await get_summary(user_id)
    return await assistant_chat_service.generate_reply(summary, request)
