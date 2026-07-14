const pool = require('../config/db');
const { getAccessibleSet, getOwnedSet } = require('../utils/accessControl');

const createCard = async (req, res) => {
  try {
    const { set_id, front, back, example, image_url } = req.body;
    if (!set_id || !front || !back) {
      return res.status(400).json({
        success: false,
        message: 'set_id, front and back are required',
      });
    }
    const owned = await getOwnedSet(req.user.id, set_id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can add cards to this set' });
    }
    const [result] = await pool.query(
      `INSERT INTO flashcards
         (set_id, user_id, front, back, example, image_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [set_id, req.user.id, front, back, example || '', image_url || null]
    );
    const [rows] = await pool.query(
      `SELECT card.*, owner.name AS creator_name
       FROM flashcards card
       JOIN users owner ON owner.id = card.user_id
       WHERE card.id = ?`,
      [result.insertId]
    );
    return res.status(201).json({ success: true, message: 'Flashcard created', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create card failed', error: error.message });
  }
};

const getCardsBySetId = async (req, res) => {
  try {
    const set = await getAccessibleSet(req.user.id, req.params.setId);
    if (!set) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not shared with you' });
    }
    const [rows] = await pool.query(
      `SELECT card.*, owner.name AS creator_name,
              review.rating AS review_rating,
              review.next_review_at
       FROM flashcards card
       JOIN users owner ON owner.id = card.user_id
       LEFT JOIN card_reviews review
         ON review.card_id = card.id AND review.user_id = ?
       WHERE card.set_id = ?
       ORDER BY card.updated_at DESC`,
      [req.user.id, req.params.setId]
    );
    return res.json({
      success: true,
      message: 'Flashcards fetched',
      data: rows,
      meta: { is_owner: set.is_owner, owner_name: set.owner_name },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch cards failed', error: error.message });
  }
};

const updateCard = async (req, res) => {
  try {
    const { front, back, example, image_url } = req.body;
    const [result] = await pool.query(
      `UPDATE flashcards
       SET front = ?, back = ?, example = ?, image_url = ?
       WHERE id = ? AND user_id = ?`,
      [front, back, example || '', image_url || null, req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can edit this card' });
    }
    const [rows] = await pool.query(
      'SELECT * FROM flashcards WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    return res.json({ success: true, message: 'Flashcard updated', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update card failed', error: error.message });
  }
};

const deleteCard = async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM flashcards WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can delete this card' });
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
