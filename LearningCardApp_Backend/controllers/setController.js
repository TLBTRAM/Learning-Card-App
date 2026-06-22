const pool = require('../config/db');

const createSet = async (req, res) => {
  try {
    const { title, description, color } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }

    const [result] = await pool.query(
      'INSERT INTO flashcard_sets (user_id, title, description, color) VALUES (?, ?, ?, ?)',
      [req.user.id, title, description || '', color || '#6C63FF']
    );

    const [rows] = await pool.query('SELECT * FROM flashcard_sets WHERE id = ?', [result.insertId]);
    return res.status(201).json({ success: true, message: 'Flashcard set created', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create set failed', error: error.message });
  }
};

const getSets = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT fs.*, COUNT(f.id) AS card_count
       FROM flashcard_sets fs
       LEFT JOIN flashcards f ON fs.id = f.set_id
       WHERE fs.user_id = ?
       GROUP BY fs.id
       ORDER BY fs.updated_at DESC`,
      [req.user.id]
    );

    return res.json({ success: true, message: 'Flashcard sets fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch sets failed', error: error.message });
  }
};

const getSetById = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM flashcard_sets WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found' });
    }

    return res.json({ success: true, message: 'Flashcard set fetched', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch set failed', error: error.message });
  }
};

const updateSet = async (req, res) => {
  try {
    const { title, description, color } = req.body;
    const [result] = await pool.query(
      'UPDATE flashcard_sets SET title = ?, description = ?, color = ? WHERE id = ? AND user_id = ?',
      [title, description || '', color || '#6C63FF', req.params.id, req.user.id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not yours' });
    }

    const [rows] = await pool.query('SELECT * FROM flashcard_sets WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Flashcard set updated', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update set failed', error: error.message });
  }
};

const deleteSet = async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM flashcard_sets WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not yours' });
    }

    return res.json({ success: true, message: 'Flashcard set deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Delete set failed', error: error.message });
  }
};

module.exports = {
  createSet,
  getSets,
  getSetById,
  updateSet,
  deleteSet,
};
