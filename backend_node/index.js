require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { seedAdmin, connectDB } = require('./db');

const authRoutes = require('./routes/auth');
const dataRoutes = require('./routes/data');

const app = express();

// CORS — allow all origins (critical for Flutter Web)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend is running', timestamp: new Date().toISOString() });
});

// Routes
app.use('/auth', authRoutes);
app.use('/data', dataRoutes);

// Start server
async function start() {
  // Connect to MongoDB Atlas first
  await connectDB();
  // Seed admin user after connection is ready
  await seedAdmin();

  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`\n🚀 Node Server running on http://localhost:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/health`);
    console.log(`🔑 Login: POST http://localhost:${PORT}/auth/login`);
    console.log(`📝 Register: POST http://localhost:${PORT}/auth/register\n`);
  });
}

start();
