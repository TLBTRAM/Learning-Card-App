const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '7d' });

const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email and password are required',
      });
    }

    const [existingUsers] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existingUsers.length) {
      return res.status(400).json({
        success: false,
        message: 'Email already exists',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashedPassword]
    );

    const [users] = await pool.query(
      'SELECT id, name, email, avatar_url, created_at, updated_at FROM users WHERE id = ?',
      [result.insertId]
    );

    return res.status(201).json({
      success: true,
      message: 'Register successful',
      token: generateToken(result.insertId),
      data: users[0],
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Register failed',
      error: error.message,
    });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (!users.length) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    return res.json({
      success: true,
      message: 'Login successful',
      token: generateToken(user.id),
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
        updated_at: user.updated_at,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message,
    });
  }
};

const getProfile = async (req, res) => {
  try {
    return res.json({
      success: true,
      message: 'Profile fetched successfully',
      data: req.user,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Cannot fetch profile',
      error: error.message,
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
};
