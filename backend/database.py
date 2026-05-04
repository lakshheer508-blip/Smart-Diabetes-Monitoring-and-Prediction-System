from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# To easily switch between PostgreSQL and SQLite without user issues
# Let's default to sqlite if postgres URL not in env, ensuring it's "runnable" out of the box in VS Code
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./diabetes_app.db")

# For sqlite we need connect_args={"check_same_thread": False}
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL, connect_args=connect_args
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
