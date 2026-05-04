from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)

    health_logs = relationship("HealthLog", back_populates="owner")
    predictions = relationship("Prediction", back_populates="owner")

class HealthLog(Base):
    __tablename__ = "health_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    glucose_level = Column(Float)
    food = Column(Float)
    exercise = Column(Float) 
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="health_logs")

class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    predicted_values = Column(String)  # Store JSON array string of predicted values
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="predictions")
