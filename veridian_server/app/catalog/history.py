import random
from datetime import datetime, timedelta

HISTORY_SEED = 2026
HISTORY_START = datetime(2026, 1, 5)
HISTORY_END = datetime(2026, 11, 20)

SALARY_AMOUNT = 350000.0
SALARY_EMPLOYER = "Veridian Payroll"
SALARY_MONTHS = range(1, 11)
SALARY_DAY = 25

PRICE_RANGE_BY_CATEGORY = {
    "entertainment": (1500, 15000),
    "food": (1500, 9000),
    "groceries": (3000, 35000),
    "services": (1500, 25000),
}

PURCHASE_COUNT_BY_CATEGORY = {
    "food": 8,
    "groceries": 7,
    "entertainment": 4,
    "services": 5,
}

SUBSCRIPTION_PAYMENTS = [
    ("Netflix", 3990, (9, 10, 11)),
    ("Spotify", 1990, (9, 10, 11)),
    ("Yandex Plus", 1490, (10, 11)),
]

TRANSFER_PEOPLE = ["Айжан К.", "Данияр С.", "Мадина Т.", "Ерлан Б.", "Алия Н."]
TRANSFER_PRICE_RANGE = (5000, 60000)
TRANSFER_COUNT_BY_TYPE = {"transfer_out": 4, "transfer_in": 4}


def build_history(brands_by_category: dict) -> list[dict]:
    rng = random.Random(HISTORY_SEED)
    messages = _salary_messages()
    messages += _transfer_messages(rng)
    messages += _subscription_messages(rng)
    messages += _purchase_messages(rng, brands_by_category)
    return sorted(messages, key=lambda message: message["date"])


def _salary_messages() -> list[dict]:
    return [
        {
            "type": "salary",
            "date": datetime(2026, month, SALARY_DAY, 10).isoformat(),
            "price": SALARY_AMOUNT,
            "counterparty": SALARY_EMPLOYER,
        }
        for month in SALARY_MONTHS
    ]


def _transfer_messages(rng: random.Random) -> list[dict]:
    low, high = TRANSFER_PRICE_RANGE
    return [
        {
            "type": transfer_type,
            "date": _random_date(rng).isoformat(),
            "price": float(rng.randrange(low, high, 100)),
            "counterparty": rng.choice(TRANSFER_PEOPLE),
        }
        for transfer_type, count in TRANSFER_COUNT_BY_TYPE.items()
        for _ in range(count)
    ]


def _subscription_messages(rng: random.Random) -> list[dict]:
    return [
        _purchase(
            brand,
            float(price),
            datetime(2026, month, rng.randint(1, 28), rng.randint(8, 22)),
        )
        for brand, price, months in SUBSCRIPTION_PAYMENTS
        for month in months
    ]


def _purchase_messages(rng: random.Random, brands_by_category: dict) -> list[dict]:
    messages = []
    for category, count in PURCHASE_COUNT_BY_CATEGORY.items():
        low, high = PRICE_RANGE_BY_CATEGORY[category]
        for _ in range(count):
            brand = rng.choice(brands_by_category[category])
            messages.append(_purchase(brand, float(rng.randrange(low, high, 10)), _random_date(rng)))
    return messages


def _purchase(brand: str, price: float, date: datetime) -> dict:
    return {
        "type": "purchase",
        "date": date.isoformat(),
        "price": price,
        "counterparty": brand,
        "brand": brand,
    }


def _random_date(rng: random.Random) -> datetime:
    days = (HISTORY_END - HISTORY_START).days
    day = HISTORY_START + timedelta(days=rng.randrange(days))
    return day.replace(hour=rng.randint(8, 22), minute=rng.randint(0, 59))
