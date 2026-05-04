const express = require('express');
const router = express.Router();
const { HealthLogDB } = require('../db');
const jwt = require('jsonwebtoken');
const axios = require('axios');

const JWT_SECRET = process.env.JWT_SECRET || '09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7';
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://127.0.0.1:8000';

// Auth middleware
const authMiddleware = (req, res, next) => {
  const token = req.header('Authorization');
  if (!token) return res.status(401).json({ detail: 'No token, authorization denied' });
  
  try {
    const decoded = jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ detail: 'Token is not valid' });
  }
};

// ──────────────── LOG HEALTH DATA ────────────────
router.post('/log_health_data', authMiddleware, async (req, res) => {
  try {
    const { glucose_level, food, exercise } = req.body;
    const newLog = await HealthLogDB.create({
      user_id: req.user.id,
      glucose_level,
      food,
      exercise
    });
    console.log('Health log saved for user: ' + req.user.sub);
    res.json(newLog);
  } catch (err) {
    console.error('Log health data error:', err);
    res.status(500).json({ detail: 'Server Error', error: err.message });
  }
});

// ──────────────── GET HEALTH LOGS ────────────────
router.get('/get_health_logs', authMiddleware, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const logs = await HealthLogDB.findByUser(req.user.id, thirtyDaysAgo);
    res.json(logs);
  } catch (err) {
    console.error('Get logs error:', err);
    res.status(500).json({ detail: 'Server Error' });
  }
});

// ──────────────── GET PREDICTIONS ────────────────
router.get('/get_predictions', authMiddleware, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const logs = await HealthLogDB.findByUser(req.user.id, thirtyDaysAgo);

    try {
      const aiResponse = await axios.post(AI_SERVICE_URL + '/predict', { logs }, { timeout: 5000 });
      res.json(aiResponse.data);
    } catch (aiErr) {
      console.log('AI service unavailable, returning empty predictions');
      res.json({ predicted_glucose: [], alerts: [], recommendations: ['AI service is currently offline.'] });
    }
  } catch (err) {
    console.error('Predictions error:', err);
    res.status(500).json({ detail: 'Server Error', error: err.message });
  }
});

// ──────────────── GET WEEKLY PREDICTIONS ────────────────
router.get('/get_weekly_predictions', authMiddleware, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const logs = await HealthLogDB.findByUser(req.user.id, thirtyDaysAgo);

    try {
      const aiResponse = await axios.post(AI_SERVICE_URL + '/predict_weekly', { logs }, { timeout: 5000 });
      res.json(aiResponse.data);
    } catch (aiErr) {
      console.log('AI service unavailable for weekly predictions');
      res.json({ predicted_glucose: [], alerts: [], recommendations: ['AI service is currently offline.'] });
    }
  } catch (err) {
    console.error('Weekly predictions error:', err);
    res.status(500).json({ detail: 'Server Error', error: err.message });
  }
});

// ──────────────── GET REPORTS ────────────────
router.get('/get_reports', authMiddleware, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const logs = await HealthLogDB.findByUser(req.user.id, thirtyDaysAgo);

    if (!logs || logs.length === 0) {
      return res.json({ summary: "No data available for the last 30 days." });
    }

    const glucoseVals = logs.map(l => l.glucose_level);
    const avg = glucoseVals.reduce((a, b) => a + b, 0) / glucoseVals.length;
    res.json({
      summary: "30-Day Health Report",
      avg_glucose: parseFloat(avg.toFixed(2)),
      max_glucose: Math.max(...glucoseVals),
      min_glucose: Math.min(...glucoseVals),
      total_logs: logs.length
    });
  } catch (err) {
    console.error('Reports error:', err);
    res.status(500).json({ detail: 'Server Error' });
  }
});

// ──────────────── DIET PLAN ────────────────

// Helper: try to get diet plan from AI service, returns null on failure
async function tryAiDietPlan(payload) {
  try {
    var resp = await axios.post(AI_SERVICE_URL + '/diet-plan', payload, { timeout: 5000 });
    return resp.data;
  } catch (e) {
    return null;
  }
}

// Built-in fallback diet plan generator
function generateFallbackDietPlan(bmi, latest_glucose, average_glucose, weight, diabetes_type) {
  var goal = 'balanced';
  var status = 'Normal';

  if (bmi != null) {
    if (bmi < 18.5) { status = 'Underweight'; goal = 'weight_gain'; }
    else if (bmi >= 30) { status = 'Obese'; goal = 'weight_loss'; }
    else if (bmi >= 25) { status = 'Overweight'; goal = 'weight_loss'; }
  }
  if (latest_glucose && latest_glucose >= 180) { goal = 'glucose_control'; }
  if (average_glucose && average_glucose >= 160) { goal = 'glucose_control'; }

  var plans = {
    balanced: [
      { day: 1, breakfast: 'Vegetable oats with milk', lunch: '2 rotis with dal, sabzi and salad', dinner: 'Brown rice with paneer curry and vegetables', snacks: 'Nuts with green tea' },
      { day: 2, breakfast: 'Poha with sprouts', lunch: 'Jeera rice with rajma and cucumber raita', dinner: 'Multigrain roti with bhindi and dal', snacks: 'Fruit bowl with seeds' },
      { day: 3, breakfast: 'Idli with sambar', lunch: 'Millet khichdi with curd and salad', dinner: 'Paneer bhurji with one phulka', snacks: 'Roasted makhana' },
      { day: 4, breakfast: 'Besan chilla with mint chutney', lunch: '2 rotis with chole and salad', dinner: 'Vegetable soup with tofu tikka', snacks: 'Buttermilk with almonds' },
      { day: 5, breakfast: 'Dalia with flax seeds and papaya', lunch: 'Brown rice with sambar and beans poriyal', dinner: 'Palak paneer with jowar roti', snacks: 'Guava with pumpkin seeds' },
      { day: 6, breakfast: 'Ragi dosa with coconut chutney', lunch: 'Quinoa pulao with dal and salad', dinner: 'Stuffed capsicum with paneer filling', snacks: 'Sprout chaat' },
      { day: 7, breakfast: 'Upma with vegetables and curd', lunch: '2 rotis with methi dal and sabzi', dinner: 'Moong dal khichdi with sauteed vegetables', snacks: 'Walnuts with herbal tea' },
    ],
    weight_loss: [
      { day: 1, breakfast: 'Vegetable oats upma with toned milk', lunch: '2 multigrain rotis with lauki sabzi, dal and salad', dinner: 'Moong dal khichdi with sauteed vegetables', snacks: 'Roasted chana with green tea' },
      { day: 2, breakfast: 'Besan chilla with mint chutney and cucumber', lunch: 'Brown rice, rajma and mixed vegetable salad', dinner: 'Paneer bhurji with stir-fried beans and carrots', snacks: 'Buttermilk with a small handful of nuts' },
      { day: 3, breakfast: 'Poha with peanuts and sprouts', lunch: '2 rotis with tinda sabzi, dal and curd', dinner: 'Vegetable soup with grilled tofu tikka', snacks: 'Apple slices with unsweetened peanut butter' },
      { day: 4, breakfast: 'Idli with sambar and coconut chutney', lunch: 'Millet khichdi with palak raita', dinner: 'Stuffed capsicum with paneer and sauteed spinach', snacks: 'Makhana roasted in ghee and black pepper' },
      { day: 5, breakfast: 'Greek yogurt with chia seeds and papaya', lunch: '2 jowar rotis with bhindi, dal and salad', dinner: 'Lemon coriander soup with mixed veg cheela', snacks: 'Coconut water and a small guava' },
      { day: 6, breakfast: 'Dalia porridge with cinnamon and flax seeds', lunch: 'Quinoa pulao with chana masala and cucumber raita', dinner: 'Palak paneer with one phulka and salad', snacks: 'Sprout chaat with lemon' },
      { day: 7, breakfast: 'Ragi dosa with sambar', lunch: '2 rotis with methi chicken or soy chunks curry and salad', dinner: 'Light dal soup with sauteed broccoli and carrots', snacks: 'Green tea with almonds and walnuts' },
    ],
    weight_gain: [
      { day: 1, breakfast: 'Paneer stuffed paratha with curd', lunch: '3 rotis with dal makhani, aloo gobi and salad', dinner: 'Jeera rice with paneer curry and curd', snacks: 'Banana shake with soaked almonds' },
      { day: 2, breakfast: 'Oats cooked in milk with dates and nuts', lunch: 'Vegetable pulao with rajma and cucumber raita', dinner: 'Moong dal chilla with paneer filling', snacks: 'Peanut chikki with buttermilk' },
      { day: 3, breakfast: 'Idli with sambar and boiled eggs or sprouts', lunch: '2 rotis with chole, beet salad and curd', dinner: 'Khichdi with ghee and mixed veg curry', snacks: 'Fruit bowl with pumpkin seeds' },
      { day: 4, breakfast: 'Poha with peanuts and a glass of milk', lunch: 'Brown rice with fish curry or soy curry and salad', dinner: 'Paneer pulao with mixed vegetable raita', snacks: 'Dates, walnuts and unsweetened lassi' },
      { day: 5, breakfast: 'Dalia with banana and nut butter', lunch: '3 rotis with dal tadka, paneer bhurji and salad', dinner: 'Vegetable sevai upma with curd', snacks: 'Roasted makhana and coconut water' },
      { day: 6, breakfast: 'Besan chilla with paneer and mint chutney', lunch: 'Quinoa or rice bowl with chana, veggies and curd', dinner: 'Stuffed paratha with dal soup', snacks: 'Smoothie with milk, oats and flax seeds' },
      { day: 7, breakfast: 'Ragi porridge with nuts and raisins', lunch: '2 rotis with chicken stew or soy curry and salad', dinner: 'Vegetable khichdi with curd and cucumber', snacks: 'Trail mix with roasted peanuts and seeds' },
    ],
    glucose_control: [
      { day: 1, breakfast: 'Steel-cut oats with chia seeds and cinnamon', lunch: '2 rotis with methi sabzi, dal and cucumber salad', dinner: 'Paneer tikka with sauteed vegetables and soup', snacks: 'Roasted chana with unsweetened green tea' },
      { day: 2, breakfast: 'Moong dal chilla with mint chutney', lunch: 'Brown rice with chana dal and lauki sabzi', dinner: 'Grilled fish or tofu with stir-fried vegetables', snacks: 'Handful of nuts and buttermilk' },
      { day: 3, breakfast: 'Vegetable poha with sprouts', lunch: '2 jowar rotis with bhindi, dal and salad', dinner: 'Moong khichdi with palak soup', snacks: 'Guava slices with pumpkin seeds' },
      { day: 4, breakfast: 'Idli with sambar and extra sprouts salad', lunch: 'Millet bowl with rajma, cucumber and curd', dinner: 'Lauki chana dal with one phulka and sauteed beans', snacks: 'Makhana roasted with turmeric and pepper' },
      { day: 5, breakfast: 'Greek yogurt with flax seeds and berries', lunch: '2 rotis with paneer bhurji, dal and salad', dinner: 'Vegetable soup with grilled tofu and broccoli', snacks: 'Apple slices with peanut butter' },
      { day: 6, breakfast: 'Ragi dosa with sambar', lunch: 'Quinoa pulao with mixed veg and curd', dinner: 'Palak paneer with one multigrain roti', snacks: 'Sprout salad with lemon' },
      { day: 7, breakfast: 'Besan cheela with spinach and paneer', lunch: '2 rotis with tori sabzi, dal and salad', dinner: 'Light dal soup with sauteed mushrooms and beans', snacks: 'Walnuts with unsweetened herbal tea' },
    ],
  };

  var dietPlan = plans[goal] || plans.balanced;
  var diabetesLabel = diabetes_type || 'diabetes-friendly';
  var summaries = {
    weight_loss: 'A ' + diabetesLabel + ' Indian meal plan focused on lower-calorie, high-fiber meals and steady glucose support.',
    weight_gain: 'A ' + diabetesLabel + ' Indian meal plan with balanced protein and calorie-dense meals for healthy weight gain.',
    glucose_control: 'A ' + diabetesLabel + ' Indian meal plan built around low-glycemic, high-fiber meals to reduce glucose spikes.',
    balanced: 'A balanced ' + diabetesLabel + ' Indian meal plan designed to keep energy steady across the week.',
  };

  return {
    status: status,
    goal: goal,
    weight: weight || 70,
    bmi: bmi || null,
    summary: summaries[goal] || summaries.balanced,
    diet_plan: dietPlan,
  };
}

router.post('/diet-plan', authMiddleware, async (req, res) => {
  try {
    var bmi = req.body.bmi || null;
    var weight = req.body.weight || 70;
    var diabetes_type = req.body.diabetes_type || 'Type 2';
    var latest_glucose = req.body.latest_glucose || null;
    var average_glucose = req.body.average_glucose || null;

    console.log('Diet plan requested by: ' + req.user.sub);

    // Try AI service first
    var aiResult = await tryAiDietPlan({
      weight: weight,
      bmi: bmi,
      diabetes_type: diabetes_type,
      latest_glucose: latest_glucose,
      average_glucose: average_glucose,
    });

    if (aiResult && aiResult.diet_plan) {
      console.log('Diet plan served from AI service');
      return res.json(aiResult);
    }

    // Fallback to built-in generator
    console.log('Using built-in diet plan fallback');
    var fallback = generateFallbackDietPlan(bmi, latest_glucose, average_glucose, weight, diabetes_type);
    return res.json(fallback);

  } catch (err) {
    console.error('Diet plan error:', err.message || err);
    res.status(500).json({ detail: 'Unable to generate diet plan right now.' });
  }
});

module.exports = router;
