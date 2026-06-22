const pool = require('../config/db');

const createCard = async (req, res) => {
  try {
    const { set_id, front, back, example, image_url } = req.body;

    if (!set_id || !front || !back) {
      return res.status(400).json({
        success: false,
        message: 'set_id, front and back are required',
      });
    }

    const [sets] = await pool.query('SELECT id FROM flashcard_sets WHERE id = ? AND user_id = ?', [set_id, req.user.id]);
    if (!sets.length) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not yours' });
    }

    const [result] = await pool.query(
      'INSERT INTO flashcards (set_id, user_id, front, back, example, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [set_id, req.user.id, front, back, example || '', image_url || null]
    );

    const [rows] = await pool.query('SELECT * FROM flashcards WHERE id = ?', [result.insertId]);
    return res.status(201).json({ success: true, message: 'Flashcard created', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create card failed', error: error.message });
  }
};

const getCardsBySetId = async (req, res) => {
  try {
    const [sets] = await pool.query('SELECT id FROM flashcard_sets WHERE id = ? AND user_id = ?', [req.params.setId, req.user.id]);
    if (!sets.length) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not yours' });
    }

    const [rows] = await pool.query(
      'SELECT * FROM flashcards WHERE set_id = ? AND user_id = ? ORDER BY updated_at DESC',
      [req.params.setId, req.user.id]
    );

    return res.json({ success: true, message: 'Flashcards fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch cards failed', error: error.message });
  }
};

const updateCard = async (req, res) => {
  try {
    const { front, back, example, image_url } = req.body;
    const [result] = await pool.query(
      'UPDATE flashcards SET front = ?, back = ?, example = ?, image_url = ? WHERE id = ? AND user_id = ?',
      [front, back, example || '', image_url || null, req.params.id, req.user.id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Flashcard not found or not yours' });
    }

    const [rows] = await pool.query('SELECT * FROM flashcards WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Flashcard updated', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update card failed', error: error.message });
  }
};

const deleteCard = async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM flashcards WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Flashcard not found or not yours' });
    }

    return res.json({ success: true, message: 'Flashcard deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Delete card failed', error: error.message });
  }
};

module.exports = {
  createCard,
  getCardsBySetId,
  updateCard,
  deleteCard,
};
