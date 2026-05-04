const express = require('express');
const router = express.Router();
const { UserDB } = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || '09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7';

// ──────────────── REGISTER ────────────────
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, age, weight, diabetes_type } = req.body;
    
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }

    const existing = await UserDB.findByEmail(email);
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const user = await UserDB.create({
      name, email, password_hash, role, age, weight, diabetes_type
    });

    console.log(`✅ New user registered: ${email}`);
    res.status(201).json({ 
      success: true,
      id: user._id, 
      name: user.name, 
      email: user.email, 
      role: user.role 
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ──────────────── LOGIN ────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password, username } = req.body;
    const loginEmail = email || username;

    console.log(`🔑 Login attempt: ${loginEmail}`);

    if (!loginEmail || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const user = await UserDB.findByEmail(loginEmail);
    if (!user) {
      console.log(`❌ User not found: ${loginEmail}`);
      return res.status(400).json({ success: false, message: 'Incorrect email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      console.log(`❌ Wrong password for: ${loginEmail}`);
      return res.status(400).json({ success: false, message: 'Incorrect email or password' });
    }

    const payload = { sub: user.email, id: user._id, role: user.role };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '24h' });

    console.log(`✅ Login successful: ${loginEmail}`);
    res.json({ 
      success: true,
      access_token: token, 
      token_type: 'bearer', 
      role: user.role,
      user: { id: user._id, name: user.name, email: user.email, role: user.role }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;
