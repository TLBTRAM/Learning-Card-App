const pool = require('../config/db');

const createNote = async (req, res) => {
  try {
    const { title, content_text, drawing_data } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }

    const [result] = await pool.query(
      'INSERT INTO notes (user_id, title, content_text, drawing_data) VALUES (?, ?, ?, ?)',
      [req.user.id, title, content_text || '', JSON.stringify(drawing_data || [])]
    );

    const [rows] = await pool.query('SELECT * FROM notes WHERE id = ? AND user_id = ?', [result.insertId, req.user.id]);
    return res.status(201).json({ success: true, message: 'Note created', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create note failed', error: error.message });
  }
};

const getNotes = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM notes WHERE user_id = ? ORDER BY updated_at DESC', [req.user.id]);
    return res.json({ success: true, message: 'Notes fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch notes failed', error: error.message });
  }
};

const getNoteById = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM notes WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Note not found or not yours' });
    }

    return res.json({ success: true, message: 'Note fetched', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch note failed', error: error.message });
  }
};

const updateNote = async (req, res) => {
  try {
    const { title, content_text, drawing_data } = req.body;
    const [result] = await pool.query(
      'UPDATE notes SET title = ?, content_text = ?, drawing_data = ? WHERE id = ? AND user_id = ?',
      [title, content_text || '', JSON.stringify(drawing_data || []), req.params.id, req.user.id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Note not found or not yours' });
    }

    const [rows] = await pool.query('SELECT * FROM notes WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return res.json({ success: true, message: 'Note updated', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update note failed', error: error.message });
  }
};

const deleteNote = async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM notes WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);

    if (!result.affectedRows) {
      return res.status(404).json({ success: false, message: 'Note not found or not yours' });
    }

    return res.json({ success: true, message: 'Note deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Delete note failed', error: error.message });
  }
};

module.exports = {
  createNote,
  getNotes,
  getNoteById,
  updateNote,
  deleteNote,
};
