from typing import Annotated, Literal, Optional

from pydantic import BaseModel, Field, field_validator

from app.catalog.brands import BRANDS_BY_CATEGORY

MAX_AMOUNT = 1_000_000_000

Money = Annotated[float, Field(gt=0, le=MAX_AMOUNT, allow_inf_nan=False)]


class Goal(BaseModel):
    amount: Money
    savedAmount: float = Field(default=0, ge=0, le=MAX_AMOUNT, allow_inf_nan=False)
    targetMonth: str = Field(pattern=r"^\d{4}-(0[1-9]|1[0-2])$")


class AssistantSettings(BaseModel):
    salary: Money
    anomalyAlerts: bool = False
    categoryLimits: dict[str, Money] = Field(default_factory=dict)
    goal: Optional[Goal] = None

    @field_validator("categoryLimits")
    @classmethod
    def check_categories(cls, limits: dict) -> dict:
        unknown = set(limits) - set(BRANDS_BY_CATEGORY)
        if unknown:
            raise ValueError(f"Unknown categories: {', '.join(sorted(unknown))}")
        return limits


class AssistantProfile(AssistantSettings):
    salary: Optional[Money] = None


class CheckRequest(BaseModel):
    kind: Literal["purchase", "transfer"]
    amount: Money
    accountId: str
    brand: Optional[str] = None


class OperationWarning(BaseModel):
    code: str
    percent: Optional[float] = None
    category: Optional[str] = None


class CheckResponse(BaseModel):
    warnings: list[OperationWarning]


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    text: str = Field(min_length=1, max_length=2000)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=500)
    language: Literal["ru", "kk", "en"] = "ru"
    history: list[ChatTurn] = Field(default_factory=list, max_length=10)


class ChatResponse(BaseModel):
    reply: str
