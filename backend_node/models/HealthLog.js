const mongoose = require('mongoose');

const HealthLogSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  glucose_level: { type: Number, required: true },
  food: { type: Number, default: 0 },
  exercise: { type: Number, default: 0 },
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model('HealthLog', HealthLogSchema);
