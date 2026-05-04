const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const HealthLog = require('./models/HealthLog');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/diabetes_app';

// Connect to MongoDB — call this before using any DB operations
async function connectDB() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB via Mongoose');
  } catch (err) {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  }
}

// ──────────────── User Operations ────────────────

const UserDB = {
  async findByEmail(email) {
    return await User.findOne({ email });
  },

  async findById(id) {
    return await User.findById(id);
  },

  async create({ name, email, password_hash, role, age, weight, diabetes_type }) {
    const user = new User({
      name, email, password_hash,
      role: role || 'Patient',
      age: age || 30,
      weight: weight || 70,
      diabetes_type: diabetes_type || 'Type 2',
      medical_history: ''
    });
    await user.save();
    return user;
  }
};

// ──────────────── HealthLog Operations ────────────────

const HealthLogDB = {
  async create({ user_id, glucose_level, food, exercise }) {
    const log = new HealthLog({
      user_id,
      glucose_level,
      food: food || 0,
      exercise: exercise || 0,
      timestamp: new Date()
    });
    await log.save();
    return log;
  },

  async findByUser(user_id, since = null) {
    const query = { user_id };
    if (since) {
      query.timestamp = { $gte: since };
    }
    return await HealthLog.find(query).sort({ timestamp: 1 });
  }
};

// ──────────────── Seed Admin User ────────────────

async function seedAdmin() {
  try {
    const existing = await UserDB.findByEmail('admin@admin.com');
    if (!existing) {
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash('password', salt);
      await UserDB.create({
        name: 'Admin',
        email: 'admin@admin.com',
        password_hash: hash,
        role: 'Doctor',
        age: 40,
        weight: 80,
        diabetes_type: 'None'
      });
      console.log('✅ Admin user created (admin@admin.com / password)');
    } else {
      console.log('✅ Admin user already exists');
    }
  } catch (err) {
    console.error('Seed Admin error:', err);
  }
}

module.exports = { UserDB, HealthLogDB, seedAdmin, connectDB, mongoose };
