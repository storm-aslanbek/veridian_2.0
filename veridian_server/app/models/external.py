from typing import List, Optional
from pydantic import BaseModel

class SupportChatRequest(BaseModel):
    message: str
    language: Optional[str] = 'ru'

class SearchResult(BaseModel):
    title: str
    link: str
    snippet: Optional[str] = None

class BusinessCheckResult(BaseModel):
    bin: Optional[List[str]] = None
    nameRu: Optional[List[str]] = None
    customerLegalAddress: Optional[str] = None
    customerBankNameRu: Optional[str] = None
    fullyPaid: Optional[float] = None
    averagePaymentTime: Optional[float] = None
    averageSigningTime: Optional[float] = None
    terminated_contracts: Optional[int] = None
    total_rating: Optional[float] = None

class JobOpportunity(BaseModel):
    job_id: str
    job_title: str
    employer_name: str
    job_city: Optional[str] = None
    job_country: Optional[str] = None
    job_apply_link: Optional[str] = None
    job_employment_type: Optional[str] = None
    job_description: Optional[str] = None