from typing import Optional
from pydantic import BaseModel

class UserResponse(BaseModel):
    id: str
    firstName: str
    surname: str
    patronymic: Optional[str] = None
    iin: str
    phone: str
    avatarUrl: Optional[str] = None
    createdAt: str
    updatedAt: str

    @property
    def name(self) -> str:
        return f"{self.firstName} {self.surname}"

class UserCreate(BaseModel):
    firstName: str
    surname: str
    patronymic: Optional[str] = None
    iin: str
    password: str
    phone: str

class Token(BaseModel):
    token: str
    user: UserResponse

class UserSearchRequest(BaseModel):
    phone: str