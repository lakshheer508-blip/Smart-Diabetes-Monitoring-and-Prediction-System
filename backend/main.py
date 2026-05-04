from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
import models, schemas, auth, database, ml_engine
import pandas as pd
from datetime import datetime, timedelta
import json

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Smart Diabetes Monitoring API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = auth.jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except auth.JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

@app.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(name=user.name, email=user.email, password_hash=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/login_json", response_model=schemas.Token)
def login_json(user_creds: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == user_creds.email).first()
    if not user or not auth.verify_password(user_creds.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/log_health_data", response_model=schemas.HealthLogResponse)
def log_health_data(log: schemas.HealthLogCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Dump the model correctly based on Pydantic v2
    new_log = models.HealthLog(**log.model_dump(), user_id=current_user.id)
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log

@app.get("/get_health_logs", response_model=list[schemas.HealthLogResponse])
def get_health_logs(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    logs = db.query(models.HealthLog).filter(
        models.HealthLog.user_id == current_user.id,
        models.HealthLog.timestamp >= thirty_days_ago
    ).order_by(models.HealthLog.timestamp.asc()).all()
    return logs

@app.get("/get_predictions", response_model=schemas.PredictionResponse)
def get_predictions(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    logs = db.query(models.HealthLog).filter(
        models.HealthLog.user_id == current_user.id,
        models.HealthLog.timestamp >= thirty_days_ago
    ).order_by(models.HealthLog.timestamp.asc()).all()

    if not logs:
        return {"predicted_glucose": [], "alerts": [], "recommendations": ["Not enough data to calculate."]}

    data = []
    for l in logs:
        data.append({
            "glucose_level": l.glucose_level,
            "food": l.food,
            "exercise": l.exercise,
            "timestamp": l.timestamp
        })
    df = pd.DataFrame(data)
    
    preds = ml_engine.generate_predictions(df)
    alerts, recommendations = ml_engine.generate_alerts_and_recommendations(df, preds)

    new_prediction = models.Prediction(
        user_id=current_user.id,
        predicted_values=json.dumps(preds)
    )
    db.add(new_prediction)
    db.commit()

    return {
        "predicted_glucose": preds,
        "alerts": alerts,
        "recommendations": recommendations
    }

@app.get("/get_weekly_predictions", response_model=schemas.PredictionResponse)
def get_weekly_predictions(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    logs = db.query(models.HealthLog).filter(
        models.HealthLog.user_id == current_user.id,
        models.HealthLog.timestamp >= thirty_days_ago
    ).order_by(models.HealthLog.timestamp.asc()).all()

    if not logs:
        return {"predicted_glucose": [], "alerts": [], "recommendations": ["Not enough data to calculate."]}

    data = []
    for l in logs:
        data.append({
            "glucose_level": l.glucose_level,
            "food": l.food,
            "exercise": l.exercise,
            "timestamp": l.timestamp
        })
    df = pd.DataFrame(data)
    
    # 28 points = 7 days * 4 points a day (every 6 hours)
    preds = ml_engine.generate_predictions(df, horizon_points=28)
    alerts, recommendations = ml_engine.generate_alerts_and_recommendations(df, preds)

    # Convert generic alerts text slightly for 1 week context
    alerts = [a.replace("72 hours", "1 week") for a in alerts]

    return {
        "predicted_glucose": preds,
        "alerts": alerts,
        "recommendations": recommendations
    }

@app.get("/get_reports")
def get_reports(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    logs = get_health_logs(current_user, db)
    if not logs:
        return {"summary": "No data available for the last 30 days."}
    
    glucose_vals = [l.glucose_level for l in logs]
    return {
        "summary": "30-Day Health Report",
        "avg_glucose": round(sum(glucose_vals) / len(glucose_vals), 2),
        "max_glucose": max(glucose_vals),
        "min_glucose": min(glucose_vals),
        "total_logs": len(logs)
    }
