import calendar
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from statistics import median
from typing import Optional

from app.catalog.brands import BRANDS_BY_CATEGORY
from app.models.assistant import AssistantProfile, Goal

PURCHASE = "purchase"
TRANSFER_OUT = "transfer_out"
SUBSCRIPTIONS = "subscriptions"

TOP_CATEGORY_COUNT = 3
SUBSCRIPTION_ACTIVE_DAYS = 45
LOW_CONFIDENCE_BEFORE_DAY = 7
LIMIT_WARNING_PERCENT = 80
LIMIT_EXCEEDED_PERCENT = 100

LARGE_SHARE_OF_SALARY = 0.30
LARGE_SHARE_OF_BALANCE = 0.50
UNUSUAL_MEDIAN_FACTOR = 3
UNUSUAL_MIN_OPERATIONS = 5
MIN_SHARE_OF_SALARY = 0.05


@dataclass(frozen=True)
class Operation:
    type: str
    date: datetime
    price: float
    category: str
    brand: Optional[str] = None


def _money(value: float) -> float:
    return round(value, 2)


def _percent(part: float, whole: float) -> float:
    return round(part / whole * 100, 1) if whole else 0.0


def _total(operations: list[Operation]) -> float:
    return sum(operation.price for operation in operations)


def _in_month(operations: list[Operation], year: int, month: int) -> list[Operation]:
    return [o for o in operations if (o.date.year, o.date.month) == (year, month)]


def _of_type(operations: list[Operation], operation_type: str) -> list[Operation]:
    return [o for o in operations if o.type == operation_type]


def _by_category(purchases: list[Operation]) -> dict[str, float]:
    totals = {category: 0.0 for category in BRANDS_BY_CATEGORY}
    for purchase in purchases:
        totals[purchase.category] = totals.get(purchase.category, 0.0) + purchase.price
    return totals


def _days_in_month(year: int, month: int) -> int:
    return calendar.monthrange(year, month)[1]


def _previous_month(today: date) -> tuple[int, int]:
    last_day = today.replace(day=1) - timedelta(days=1)
    return last_day.year, last_day.month


def _add_month(day: date) -> date:
    year, month = (day.year + 1, 1) if day.month == 12 else (day.year, day.month + 1)
    return date(year, month, min(day.day, _days_in_month(year, month)))


def _categories(current: list[Operation], previous: list[Operation]) -> list[dict]:
    totals, previous_totals = _by_category(current), _by_category(previous)
    expenses = _total(current)
    items = [
        {
            "category": category,
            "amount": _money(amount),
            "percent": _percent(amount, expenses),
            "previousAmount": _money(previous_totals.get(category, 0.0)),
        }
        for category, amount in totals.items()
    ]
    return sorted(items, key=lambda item: item["amount"], reverse=True)


def _comparison(current: list[Operation], previous: list[Operation], today: date) -> dict:
    year, month = _previous_month(today)
    previous_days = _days_in_month(year, month)
    is_month_end = today.day == _days_in_month(today.year, today.month)
    cutoff = previous_days if is_month_end else min(today.day, previous_days)

    expenses = _total(current)
    same_period = _total([o for o in previous if o.date.day <= cutoff])
    return {
        "previousMonth": f"{year}-{month:02d}",
        "cutoffDay": cutoff,
        "previousSamePeriod": _money(same_period),
        "previousFull": _money(_total(previous)),
        "difference": _money(expenses - same_period),
        "changePercent": _percent(expenses - same_period, same_period) if same_period else None,
    }


def _subscriptions(purchases: list[Operation], today: date) -> list[dict]:
    last_by_brand: dict[str, Operation] = {}
    for purchase in sorted(purchases, key=lambda o: o.date):
        if purchase.category == SUBSCRIPTIONS:
            last_by_brand[purchase.brand] = purchase

    items = []
    for brand, last in last_by_brand.items():
        if (today - last.date.date()).days > SUBSCRIPTION_ACTIVE_DAYS:
            continue
        next_charge = _add_month(last.date.date())
        items.append({
            "brand": brand,
            "price": _money(last.price),
            "nextChargeDate": next_charge.isoformat(),
            "overdue": next_charge < today,
        })
    return sorted(items, key=lambda item: item["nextChargeDate"])


def _upcoming_this_month(subscriptions: list[dict], today: date) -> float:
    month_end = today.replace(day=_days_in_month(today.year, today.month))
    return sum(
        item["price"] for item in subscriptions
        if today <= date.fromisoformat(item["nextChargeDate"]) <= month_end
    )


def _forecast_expenses(current: list[Operation], today: date, upcoming: float) -> float:
    expenses = _total(current)
    paid_subscriptions = _total([o for o in current if o.category == SUBSCRIPTIONS])
    daily = (expenses - paid_subscriptions) / today.day
    days_ahead = _days_in_month(today.year, today.month) - today.day
    return expenses + daily * days_ahead + upcoming


def _goal(goal: Optional[Goal], today: date, forecast_left: float) -> Optional[dict]:
    if goal is None:
        return None
    year, month = map(int, goal.targetMonth.split("-"))
    months_left = (year - today.year) * 12 + (month - today.month) + 1
    remaining = max(0.0, goal.amount - goal.savedAmount)
    required = 0.0
    if remaining == 0:
        status = "achieved"
    elif months_left <= 0:
        status = "expired"
    else:
        required = remaining / months_left
        status = "on_track" if forecast_left >= required else "behind"
    return {
        **goal.model_dump(),
        "monthsLeft": max(0, months_left),
        "requiredMonthly": _money(required),
        "status": status,
    }


def _safe_to_spend(salary_left: float, balance: float, today: date,
                   subscriptions: float, goal_saving: float) -> dict:
    available = max(0.0, min(salary_left, balance) - subscriptions - goal_saving)
    days_left = _days_in_month(today.year, today.month) - today.day + 1
    return {
        "perDay": _money(available / days_left),
        "available": _money(available),
        "daysLeft": days_left,
        "reservedSubscriptions": _money(subscriptions),
        "reservedGoal": _money(goal_saving),
    }


def _limit_status(spent: float, limit: float) -> str:
    percent = spent / limit * 100
    if percent >= LIMIT_EXCEEDED_PERCENT:
        return "exceeded"
    return "warning" if percent >= LIMIT_WARNING_PERCENT else "ok"


def _limits(limits: dict[str, float], spent: dict[str, float]) -> list[dict]:
    return [
        {
            "category": category,
            "limit": _money(limit),
            "spent": _money(spent.get(category, 0.0)),
            "percent": _percent(spent.get(category, 0.0), limit),
            "status": _limit_status(spent.get(category, 0.0), limit),
        }
        for category, limit in limits.items()
    ]


def build_summary(operations: list[Operation], profile: AssistantProfile,
                  balance: float, now: datetime) -> dict:
    today = now.date()
    happened = [o for o in operations if o.date <= now]
    purchases = _of_type(happened, PURCHASE)
    current = _in_month(purchases, today.year, today.month)
    previous = _in_month(purchases, *_previous_month(today))
    comparison = _comparison(current, previous, today)

    expenses = _total(current)
    transfers = _total(_in_month(_of_type(happened, TRANSFER_OUT), today.year, today.month))
    salary_left = profile.salary - expenses - transfers

    subscriptions = _subscriptions(purchases, today)
    monthly_subscriptions = sum(item["price"] for item in subscriptions)
    upcoming = _upcoming_this_month(subscriptions, today)
    forecast_expenses = _forecast_expenses(current, today, upcoming)
    forecast_left = profile.salary - forecast_expenses - transfers
    goal = _goal(profile.goal, today, forecast_left)
    goal_saving = goal["requiredMonthly"] if goal else 0.0

    same_period = [o for o in previous if o.date.day <= comparison["cutoffDay"]]
    categories = _categories(current, same_period)
    return {
        "month": f"{today.year}-{today.month:02d}",
        "day": today.day,
        "daysInMonth": _days_in_month(today.year, today.month),
        "salary": profile.salary,
        "totalExpenses": _money(expenses),
        "categories": categories,
        "topCategories": [
            {key: item[key] for key in ("category", "amount", "percent")}
            for item in categories[:TOP_CATEGORY_COUNT] if item["amount"] > 0
        ],
        "comparison": comparison,
        "transfersOut": _money(transfers),
        "salaryLeft": _money(salary_left),
        "balance": _money(balance),
        "forecast": {
            "expenses": _money(forecast_expenses),
            "left": _money(forecast_left),
            "lowConfidence": today.day < LOW_CONFIDENCE_BEFORE_DAY,
        },
        "safeToSpend": _safe_to_spend(salary_left, balance, today, upcoming, goal_saving),
        "subscriptions": {
            "monthlyTotal": _money(monthly_subscriptions),
            "yearlyTotal": _money(monthly_subscriptions * 12),
            "items": subscriptions,
        },
        "limits": _limits(profile.categoryLimits, _by_category(current)),
        "goal": goal,
    }


def anomaly_warnings(amount: float, salary: float, balance: float,
                     similar_amounts: list[float]) -> list[dict]:
    warnings = []
    is_noticeable = amount >= salary * MIN_SHARE_OF_SALARY
    if amount >= salary * LARGE_SHARE_OF_SALARY:
        warnings.append({"code": "large_vs_salary", "percent": _percent(amount, salary)})
    if is_noticeable and balance > 0 and amount >= balance * LARGE_SHARE_OF_BALANCE:
        warnings.append({"code": "large_vs_balance", "percent": _percent(amount, balance)})
    if (is_noticeable and len(similar_amounts) >= UNUSUAL_MIN_OPERATIONS
            and amount >= median(similar_amounts) * UNUSUAL_MEDIAN_FACTOR):
        warnings.append({"code": "unusual_amount"})
    return warnings


def limit_warnings(operations: list[Operation], limits: dict[str, float],
                   category: str, amount: float, now: datetime) -> list[dict]:
    limit = limits.get(category)
    if limit is None:
        return []
    current = _in_month(_of_type(operations, PURCHASE), now.year, now.month)
    spent = _by_category(current).get(category, 0.0) + amount
    status = _limit_status(spent, limit)
    if status == "ok":
        return []
    return [{"code": f"limit_{status}", "category": category, "percent": _percent(spent, limit)}]
