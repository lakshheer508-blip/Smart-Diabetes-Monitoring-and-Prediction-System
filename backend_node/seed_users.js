const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const MONGO_URI = 'mongodb://127.0.0.1:27017/smart_diabetes';

const users = [
  { name: 'Admin', email: 'admin@admin.com', password: 'password', role: 'Doctor', age: 40, weight: 80, diabetes_type: 'None' },
  { name: 'Test User 1', email: 'user1@test.com', password: 'password123', role: 'Patient', age: 30, weight: 70, diabetes_type: 'Type 2' },
  { name: 'Test User 2', email: 'user2@test.com', password: 'password123', role: 'Patient', age: 45, weight: 82, diabetes_type: 'Type 1' },
  { name: 'Doctor Smith', email: 'doctor@test.com', password: 'password123', role: 'Doctor', age: 50, weight: 75, diabetes_type: 'None' }
];

async function seed() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to DB');

    for (const u of users) {
      let existing = await User.findOne({ email: u.email });
      if (!existing) {
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(u.password, salt);
        await User.create({
          name: u.name,
          email: u.email,
          password_hash: hash,
          role: u.role,
          age: u.age,
          weight: u.weight,
          diabetes_type: u.diabetes_type
        });
        console.log(`Created user: ${u.email}`);
      } else {
        console.log(`User ${u.email} already exists`);
      }
    }
  } catch (err) {
    console.error(err);
  } finally {
    mongoose.disconnect();
  }
}

seed();
