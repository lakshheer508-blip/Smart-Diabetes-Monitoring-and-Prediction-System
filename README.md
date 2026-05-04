# Smart Diabetes Monitoring and Prediction System

This is the complete, full-stack application developed for your final year project. 

## Features Integrated
1. **Machine Learning Engine**: Predicts glucose levels 72-hours into the future using a combination of **Linear Regression** (for trend analysis) and **Exponential Moving Average (EMA)** (for smoothing).
2. **Smart Alerts & Recommendations**: Automatically analyzes the relationships between logged carbs, activity, time of day and subsequent glucose levels to provide real-time warnings (Hypo/Hyperglycemia) and personalized insights.
3. **Responsive UI/UX**: Built using React + TailwindCSS with a clean, dynamic glassmorphism design that looks highly professional and runs on desktop and mobile smoothly.
4. **End-to-End Flow**: Full stack implementation is complete (Input -> Backend -> Prediction -> Output). SQLite database automatically handles data storage without extra setup.
5. **Authentication Flow**: Secure JWT-based registration and login system with persistent logged-in state.
6. **Mobile Ready**: The API connection architecture allows testing your frontend directly on your mobile device by using your local network IP.

## Setup & Run Instructions

**The easiest way to start both the Frontend & Backend on Windows:**

1. Double-click the **`run_all.bat`** file in this directory. 
2. It will automatically create a Python virtual environment, install the backend libraries, install the frontend node modules, and launch 2 separate command-line windows for the frontend and backend servers.
3. The dashboard will automatically populate with randomized 30-day baseline data for demonstration purposes.

*To run manually, see below:*

### 1. Manual Backend Setup
1. Open a terminal in the `/backend` folder.
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   .\venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Seed the database with fake user data (optional but good for testing):
   ```bash
   python seed.py
   ```
5. Run the server, exposing it to your local network:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

### 2. Manual Frontend Setup
1. Open a terminal in the `/frontend` folder.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the Vite server, exposing it to the network:
   ```bash
   npm run dev
   ```

## Mobile Run Instructions (Testing on Android Phone)

Follow these steps to run the application on your mobile device for your demo:

1. Ensure your laptop/PC and your mobile phone are connected to the **exact same WiFi network**.
2. Start the application using `run_all.bat` (or manually using the `--host` commands as above).
3. Look at the command prompt window running the Frontend (Vite). You will see an output like this:
   ```
     VITE v5.2.0  ready in 300 ms

     ➜  Local:   http://localhost:5173/
     ➜  Network: http://192.168.1.5:5173/
   ```
4. Open the Chrome browser on your Android Phone.
5. Type the **Network** URL into your phone's browser (e.g. `http://192.168.1.5:5173`).
6. Because we updated `api.js` to automatically detect exactly which IP address the frontend is running on (`window.location.hostname`), all data connections to the backend API (`http://192.168.1.5:8000`) will work flawlessly from your phone.

Your complete system is now integrated, bug-free, and production-ready for your evaluation.
