import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression

def generate_predictions(df: pd.DataFrame, horizon_points: int = 12):
    if df.empty:
        return [100.0] * horizon_points

    if len(df) < 5:
        # Not enough data for LR, return a simple flat prediction based on last value
        last_val = df['glucose_level'].iloc[-1]
        return [last_val] * horizon_points

    df = df.copy()
    df = df.sort_values('timestamp')
    df['time_idx'] = np.arange(len(df))

    # EMA
    df['ema'] = df['glucose_level'].ewm(span=5, adjust=False).mean()

    # Linear Regression to find trend
    X = df[['time_idx']]
    y = df['glucose_level']
    model = LinearRegression()
    model.fit(X, y)

    last_idx = df['time_idx'].iloc[-1]
    future_X = np.array([[last_idx + i] for i in range(1, horizon_points + 1)])
    lr_preds = model.predict(future_X)

    # Combine EMA and LR for final prediction (weighted average)
    last_ema = df['ema'].iloc[-1]
    
    final_preds = []
    current_val = last_ema
    for p in lr_preds:
        # weight towards the trend but smooth it
        nxt = (current_val * 0.7) + (p * 0.3)
        final_preds.append(round(nxt, 2))
        current_val = nxt

    return final_preds

def generate_alerts_and_recommendations(df: pd.DataFrame, preds: list):
    alerts = []
    recommendations = []
    
    if not preds:
        return alerts, recommendations

    min_pred = min(preds)
    max_pred = max(preds)

    if min_pred < 70:
        alerts.append("Hypoglycemia Alert: Glucose levels predicted to drop below 70 mg/dL in the next 72 hours.")
    if max_pred > 180:
        alerts.append("Hyperglycemia Alert: Glucose levels predicted to exceed 180 mg/dL in the next 72 hours.")

    if not df.empty:
        # Correlation checks
        if 'food' in df.columns and 'glucose_level' in df.columns and len(df) > 5:
            corr_food = df['food'].corr(df['glucose_level'])
            if pd.notna(corr_food) and corr_food > 0.5:
                recommendations.append("High food intake shows a strong correlation with your glucose spikes. Consider modifying your meal portions.")
        
        if 'exercise' in df.columns and 'glucose_level' in df.columns and len(df) > 5:
            corr_act = df['exercise'].corr(df['glucose_level'])
            if pd.notna(corr_act) and corr_act < -0.3:
                recommendations.append("Low exercise correlates with higher glucose. Try to increase daily exercise minutes.")

        # Night time food
        df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
        night_logs = df[(df['hour'] >= 20) | (df['hour'] <= 4)]
        if not night_logs.empty and night_logs['food'].mean() > 40:
            recommendations.append("High food intake at night leads to morning spikes.")

    if not recommendations:
        recommendations.append("Maintain a balanced diet and regular activity.")
        
    return alerts, recommendations
