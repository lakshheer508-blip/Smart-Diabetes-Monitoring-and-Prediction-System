import database, models, auth
from datetime import datetime, timedelta
import random

def seed_data():
    db = database.SessionLocal()
    email = "test@example.com"
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        pwd = auth.get_password_hash("password")
        user = models.User(name="Test User", email=email, password_hash=pwd)
        db.add(user)
        db.commit()
        db.refresh(user)

    existing_logs = db.query(models.HealthLog).filter(models.HealthLog.user_id == user.id).first()
    if not existing_logs:
        start_date = datetime.utcnow() - timedelta(days=30)
        logs = []
        for i in range(30 * 4):
            log_time = start_date + timedelta(hours=i*6)
            carbs = random.uniform(20, 100)
            activity = random.uniform(0, 60)
            
            base_glucose = 100
            if log_time.hour >= 20 or log_time.hour <= 4:
                carbs += random.uniform(0, 30)
                
            glucose = base_glucose + (carbs * 0.5) - (activity * 0.3) + random.uniform(-10, 10)
            
            log = models.HealthLog(
                user_id=user.id,
                glucose_level=round(glucose, 2),
                calories=round(carbs * 4 + random.uniform(200, 400), 2),
                carbs=round(carbs, 2),
                activity=round(activity, 2),
                timestamp=log_time
            )
            logs.append(log)
            
        db.bulk_save_objects(logs)
        db.commit()
        print("Database seeded with sample data.")
    else:
        print("Data already exists.")

    db.close()

if __name__ == "__main__":
    models.Base.metadata.create_all(bind=database.engine)
    seed_data()
