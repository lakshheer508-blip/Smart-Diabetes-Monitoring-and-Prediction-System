const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password_hash: { type: String, required: true },
  role: { type: String, enum: ['Patient', 'Doctor', 'Admin'], default: 'Patient' },
  age: { type: Number },
  weight: { type: Number },
  diabetes_type: { type: String, enum: ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetes', 'None'], default: 'Type 2' },
  medical_history: { type: String },
});

module.exports = mongoose.model('User', UserSchema);
