@echo off
echo ===================================================
echo Smart Diabetes Monitoring System - Full Stack Startup
echo ===================================================

echo [1] Checking and installing AI Microservice dependencies...
cd ai_service
if not exist "venv" (
    echo Creating virtual environment for AI...
    python -m venv venv
)
call venv\Scripts\activate
pip install -r requirements.txt
echo [2] Starting AI Server on port 8000...
start cmd /k "title AI Microservice && venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8000"
cd ..

echo [3] Checking and installing Node.js Backend dependencies...
cd backend_node
if not exist "node_modules" (
    echo Installing node modules for backend...
    npm install
)
echo [4] Starting Node Backend Server on port 5000...
start cmd /k "title Node Backend && node index.js"
cd ..

echo [5] Checking and getting Flutter App dependencies...
cd flutter_app
call flutter pub get

echo [6] Starting Flutter App on local web server...
start cmd /k "title Flutter Frontend && flutter run -d web-server --web-port 3000"
echo ===================================================
echo System is starting up...
echo 1. AI Service running at http://localhost:8000
echo 2. Node Backend running at http://localhost:5000 
echo 3. Flutter App running locally via Chrome.
echo ===================================================
pause
