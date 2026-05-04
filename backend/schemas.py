from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr

    class Config:
        from_attributes = True

class HealthLogCreate(BaseModel):
    glucose_level: float
    food: float
    exercise: float

class HealthLogResponse(HealthLogCreate):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class PredictionResponse(BaseModel):
    predicted_glucose: List[float]
    alerts: List[str]
    recommendations: List[str]

class Token(BaseModel):
    access_token: str
    token_type: str
