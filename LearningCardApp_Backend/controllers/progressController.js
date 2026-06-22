const pool = require('../config/db');

const saveProgress = async (req, res) => {
  try {
    const { set_id, total_cards, learned_cards, correct_answers, wrong_answers } = req.body;

    if (!set_id) {
      return res.status(400).json({ success: false, message: 'set_id is required' });
    }

    const [sets] = await pool.query('SELECT id FROM flashcard_sets WHERE id = ? AND user_id = ?', [set_id, req.user.id]);
    if (!sets.length) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not yours' });
    }

    await pool.query(
      `INSERT INTO study_progress (user_id, set_id, total_cards, learned_cards, correct_answers, wrong_answers, last_studied_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE
         total_cards = VALUES(total_cards),
         learned_cards = VALUES(learned_cards),
         correct_answers = VALUES(correct_answers),
         wrong_answers = VALUES(wrong_answers),
         last_studied_at = NOW()`,
      [
        req.user.id,
        set_id,
        total_cards || 0,
        learned_cards || 0,
        correct_answers || 0,
        wrong_answers || 0,
      ]
    );

    const [rows] = await pool.query('SELECT * FROM study_progress WHERE user_id = ? AND set_id = ?', [req.user.id, set_id]);
    return res.json({ success: true, message: 'Study progress saved', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Save progress failed', error: error.message });
  }
};

const getProgressBySetId = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM study_progress WHERE user_id = ? AND set_id = ?', [req.user.id, req.params.setId]);

    return res.json({
      success: true,
      message: 'Study progress fetched',
      data: rows[0] || null,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch progress failed', error: error.message });
  }
};

module.exports = {
  saveProgress,
  getProgressBySetId,
};
