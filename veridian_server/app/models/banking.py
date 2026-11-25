from typing import Optional
from pydantic import BaseModel

from app.models.assistant import Money

class BankAccount(BaseModel):
    id: str
    userId: str
    accountNumber: str
    accountName: str
    accountType: str
    balance: float
    currency: str
    isActive: bool
    createdAt: str
    updatedAt: str

class Card(BaseModel):
    id: str
    userId: str
    accountId: str
    cardNumber: str
    cardHolderName: str
    expiryDate: str
    cvv: str
    cardType: str
    status: str
    cardColor: Optional[str] = "0xFF1E1E1E"
    createdAt: str
    updatedAt: str

class Transaction(BaseModel):
    id: str
    userId: str
    accountId: str
    type: str
    category: str
    amount: float
    currency: str
    recipient: Optional[str] = None
    description: Optional[str] = None
    status: str
    transactionDate: str
    createdAt: str
    updatedAt: str

class TransferRequest(BaseModel):
    accountId: str
    cardNumber: str
    amount: Money
    description: Optional[str] = None

class TransferByPhoneRequest(BaseModel):
    accountId: str
    phoneNumber: str
    amount: Money
    description: Optional[str] = None

class Bill(BaseModel):
    id: str
    userId: str
    payeeName: str
    category: str
    amount: float
    currency: str
    dueDate: str
    isPaid: bool
    createdAt: str
    updatedAt: str

class Loan(BaseModel):
    id: str
    userId: str
    provider: str
    amount: float
    remainingAmount: float
    currency: str
    interestRate: float
    nextPaymentDate: str
    status: str
    createdAt: str
    updatedAt: str

class TransferRecipient(BaseModel):
    id: str
    userId: str
    name: str
    accountNumber: str
    bankName: str
    recipientType: str
    isFavorite: bool
    createdAt: str
    updatedAt: str