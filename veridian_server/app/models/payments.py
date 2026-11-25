from typing import Optional

from pydantic import BaseModel

from app.models.assistant import Money


class Brand(BaseModel):
    name: str
    category: str


class Payment(BaseModel):
    id: str
    type: str
    date: str
    price: float
    counterparty: str
    brand: Optional[str] = None
    category: str
    isRead: bool


class PurchaseRequest(BaseModel):
    accountId: str
    brand: str
    price: Money
