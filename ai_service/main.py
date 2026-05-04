from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import ml_engine
from typing import Optional

app = FastAPI(title="Smart Diabetes AI Microservice")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LogData(BaseModel):
    logs: list

class PredictionRequest(BaseModel):
    logs: list


class DietPlanRequest(BaseModel):
    weight: Optional[float] = 70
    bmi: Optional[float] = None
    diabetes_type: Optional[str] = "Type 2"
    latest_glucose: Optional[float] = None
    average_glucose: Optional[float] = None


def _resolve_health_status(bmi: Optional[float]) -> str:
    if bmi is None:
        return "Unknown"
    if bmi < 18.5:
        return "Underweight"
    if bmi >= 30:
        return "Obese"
    if bmi >= 25:
        return "Overweight"
    return "Normal"


def _resolve_goal(
    bmi: Optional[float],
    latest_glucose: Optional[float],
    average_glucose: Optional[float],
) -> tuple[str, str]:
    status = _resolve_health_status(bmi)

    if latest_glucose is not None and latest_glucose >= 180:
        return status, "glucose_control"
    if average_glucose is not None and average_glucose >= 160:
        return status, "glucose_control"
    if status in {"Overweight", "Obese"}:
        return status, "weight_loss"
    if status == "Underweight":
        return status, "weight_gain"
    return status, "balanced"


def _diet_templates(goal: str) -> list[dict]:
    if goal == "weight_loss":
        return [
            {
                "breakfast": "Vegetable oats upma with toned milk",
                "lunch": "2 multigrain rotis with lauki sabzi, dal and salad",
                "dinner": "Moong dal khichdi with sauteed vegetables",
                "snacks": "Roasted chana with green tea",
            },
            {
                "breakfast": "Besan chilla with mint chutney and cucumber",
                "lunch": "Brown rice, rajma and mixed vegetable salad",
                "dinner": "Paneer bhurji with stir-fried beans and carrots",
                "snacks": "Buttermilk with a small handful of nuts",
            },
            {
                "breakfast": "Poha with peanuts and sprouts",
                "lunch": "2 rotis with tinda sabzi, dal and curd",
                "dinner": "Vegetable soup with grilled tofu tikka",
                "snacks": "Apple slices with unsweetened peanut butter",
            },
            {
                "breakfast": "Idli with sambar and coconut chutney",
                "lunch": "Millet khichdi with palak raita",
                "dinner": "Stuffed capsicum with paneer and sauteed spinach",
                "snacks": "Makhana roasted in ghee and black pepper",
            },
            {
                "breakfast": "Greek yogurt with chia seeds and papaya",
                "lunch": "2 jowar rotis with bhindi, dal and salad",
                "dinner": "Lemon coriander soup with mixed veg cheela",
                "snacks": "Coconut water and a small guava",
            },
            {
                "breakfast": "Dalia porridge with cinnamon and flax seeds",
                "lunch": "Quinoa pulao with chana masala and cucumber raita",
                "dinner": "Palak paneer with one phulka and salad",
                "snacks": "Sprout chaat with lemon",
            },
            {
                "breakfast": "Ragi dosa with sambar",
                "lunch": "2 rotis with methi chicken or soy chunks curry and salad",
                "dinner": "Light dal soup with sauteed broccoli and carrots",
                "snacks": "Green tea with almonds and walnuts",
            },
        ]

    if goal == "weight_gain":
        return [
            {
                "breakfast": "Paneer stuffed paratha with curd",
                "lunch": "3 rotis with dal makhani, aloo gobi and salad",
                "dinner": "Jeera rice with paneer curry and curd",
                "snacks": "Banana shake with soaked almonds",
            },
            {
                "breakfast": "Oats cooked in milk with dates and nuts",
                "lunch": "Vegetable pulao with rajma and cucumber raita",
                "dinner": "Moong dal chilla with paneer filling",
                "snacks": "Peanut chikki with buttermilk",
            },
            {
                "breakfast": "Idli with sambar and boiled eggs or sprouts",
                "lunch": "2 rotis with chole, beet salad and curd",
                "dinner": "Khichdi with ghee and mixed veg curry",
                "snacks": "Fruit bowl with pumpkin seeds",
            },
            {
                "breakfast": "Poha with peanuts and a glass of milk",
                "lunch": "Brown rice with fish curry or soy curry and salad",
                "dinner": "Paneer pulao with mixed vegetable raita",
                "snacks": "Dates, walnuts and unsweetened lassi",
            },
            {
                "breakfast": "Dalia with banana and nut butter",
                "lunch": "3 rotis with dal tadka, paneer bhurji and salad",
                "dinner": "Vegetable sevai upma with curd",
                "snacks": "Roasted makhana and coconut water",
            },
            {
                "breakfast": "Besan chilla with paneer and mint chutney",
                "lunch": "Quinoa or rice bowl with chana, veggies and curd",
                "dinner": "Stuffed paratha with dal soup",
                "snacks": "Smoothie with milk, oats and flax seeds",
            },
            {
                "breakfast": "Ragi porridge with nuts and raisins",
                "lunch": "2 rotis with chicken stew or soy curry and salad",
                "dinner": "Vegetable khichdi with curd and cucumber",
                "snacks": "Trail mix with roasted peanuts and seeds",
            },
        ]

    if goal == "glucose_control":
        return [
            {
                "breakfast": "Steel-cut oats with chia seeds and cinnamon",
                "lunch": "2 rotis with methi sabzi, dal and cucumber salad",
                "dinner": "Paneer tikka with sauteed vegetables and soup",
                "snacks": "Roasted chana with unsweetened green tea",
            },
            {
                "breakfast": "Moong dal chilla with mint chutney",
                "lunch": "Brown rice with chana dal and lauki sabzi",
                "dinner": "Grilled fish or tofu with stir-fried vegetables",
                "snacks": "Handful of nuts and buttermilk",
            },
            {
                "breakfast": "Vegetable poha with sprouts",
                "lunch": "2 jowar rotis with bhindi, dal and salad",
                "dinner": "Moong khichdi with palak soup",
                "snacks": "Guava slices with pumpkin seeds",
            },
            {
                "breakfast": "Idli with sambar and extra sprouts salad",
                "lunch": "Millet bowl with rajma, cucumber and curd",
                "dinner": "Lauki chana dal with one phulka and sauteed beans",
                "snacks": "Makhana roasted with turmeric and pepper",
            },
            {
                "breakfast": "Greek yogurt with flax seeds and berries",
                "lunch": "2 rotis with paneer bhurji, dal and salad",
                "dinner": "Vegetable soup with grilled tofu and broccoli",
                "snacks": "Apple slices with peanut butter",
            },
            {
                "breakfast": "Ragi dosa with sambar",
                "lunch": "Quinoa pulao with mixed veg and curd",
                "dinner": "Palak paneer with one multigrain roti",
                "snacks": "Sprout salad with lemon",
            },
            {
                "breakfast": "Besan cheela with spinach and paneer",
                "lunch": "2 rotis with tori sabzi, dal and salad",
                "dinner": "Light dal soup with sauteed mushrooms and beans",
                "snacks": "Walnuts with unsweetened herbal tea",
            },
        ]

    return [
        {
            "breakfast": "Vegetable oats with milk",
            "lunch": "2 rotis with dal, sabzi and salad",
            "dinner": "Brown rice with paneer curry and vegetables",
            "snacks": "Nuts with green tea",
        },
        {
            "breakfast": "Poha with sprouts",
            "lunch": "Jeera rice with rajma and cucumber raita",
            "dinner": "Multigrain roti with bhindi and dal",
            "snacks": "Fruit bowl with seeds",
        },
        {
            "breakfast": "Idli with sambar",
            "lunch": "Millet khichdi with curd and salad",
            "dinner": "Paneer bhurji with one phulka",
            "snacks": "Roasted makhana",
        },
        {
            "breakfast": "Besan chilla with mint chutney",
            "lunch": "2 rotis with chole and salad",
            "dinner": "Vegetable soup with tofu tikka",
            "snacks": "Buttermilk with almonds",
        },
        {
            "breakfast": "Dalia with flax seeds and papaya",
            "lunch": "Brown rice with sambar and beans poriyal",
            "dinner": "Palak paneer with jowar roti",
            "snacks": "Guava with pumpkin seeds",
        },
        {
            "breakfast": "Ragi dosa with coconut chutney",
            "lunch": "Quinoa pulao with dal and salad",
            "dinner": "Stuffed capsicum with paneer filling",
            "snacks": "Sprout chaat",
        },
        {
            "breakfast": "Upma with vegetables and curd",
            "lunch": "2 rotis with methi dal and sabzi",
            "dinner": "Moong dal khichdi with sauteed vegetables",
            "snacks": "Walnuts with herbal tea",
        },
    ]


def _build_summary(goal: str, diabetes_type: Optional[str]) -> str:
    diabetes_label = diabetes_type or "diabetes-friendly"

    summaries = {
        "weight_loss": f"A {diabetes_label} Indian meal plan focused on lower-calorie, high-fiber meals and steady glucose support.",
        "weight_gain": f"A {diabetes_label} Indian meal plan with balanced protein and calorie-dense meals for healthy weight gain.",
        "glucose_control": f"A {diabetes_label} Indian meal plan built around low-glycemic, high-fiber meals to reduce glucose spikes.",
        "balanced": f"A balanced {diabetes_label} Indian meal plan designed to keep energy steady across the week.",
    }

    return summaries.get(goal, summaries["balanced"])

@app.post("/predict")
def predict_glucose(req: PredictionRequest):
    if not req.logs:
        return {"predicted_glucose": [], "alerts": [], "recommendations": ["Not enough data to calculate."]}

    # Convert node logs to expected pandas df
    df = pd.DataFrame(req.logs)
    
    # Needs columns: glucose_level, food, exercise, timestamp
    preds = ml_engine.generate_predictions(df, horizon_points=12) # 72 hours
    alerts, recommendations = ml_engine.generate_alerts_and_recommendations(df, preds)

    return {
        "predicted_glucose": preds,
        "alerts": alerts,
        "recommendations": recommendations,
        "xai_explanation": "Prediction based on Linear Regression and Exponential Moving Average. Weighting recent changes 70% and trend 30%."
    }

@app.post("/predict_weekly")
def predict_glucose_weekly(req: PredictionRequest):
    if not req.logs:
        return {"predicted_glucose": [], "alerts": [], "recommendations": ["Not enough data to calculate."]}

    # Convert node logs to expected pandas df
    df = pd.DataFrame(req.logs)
    
    # 28 points = 7 days * 4 points a day (every 6 hours)
    preds = ml_engine.generate_predictions(df, horizon_points=28) 
    alerts, recommendations = ml_engine.generate_alerts_and_recommendations(df, preds)

    alerts = [a.replace("72 hours", "1 week") for a in alerts]

    return {
        "predicted_glucose": preds,
        "alerts": alerts,
        "recommendations": recommendations,
        "xai_explanation": "7-day projection modeling long-term behavioral trends and diet stability."
    }

@app.post("/diet-plan")
def generate_diet_plan(req: DietPlanRequest):
    status, goal = _resolve_goal(req.bmi, req.latest_glucose, req.average_glucose)
    plan = _diet_templates(goal)

    diet_plan = []
    for index, day in enumerate(plan, start=1):
        diet_plan.append(
            {
                "day": index,
                "breakfast": day["breakfast"],
                "lunch": day["lunch"],
                "dinner": day["dinner"],
                "snacks": day["snacks"],
            }
        )

    return {
        "status": status,
        "goal": goal,
        "weight": req.weight,
        "bmi": req.bmi,
        "summary": _build_summary(goal, req.diabetes_type),
        "diet_plan": diet_plan,
    }

@app.post("/image-analysis")
def analyze_image(req: dict):
    # Dummy image analysis for Phase 2
    return {
        "detected_body_type": "Endomorph",
        "estimated_weight": 82,
        "estimated_bmi": 28.5,
        "diabetes_risk": "Moderate",
        "diet_generated": True
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
