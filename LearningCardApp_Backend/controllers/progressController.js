const pool = require('../config/db');
const { getAccessibleSet } = require('../utils/accessControl');

const saveProgress = async (req, res) => {
  try {
    const {
      set_id,
      total_cards,
      learned_cards,
      correct_answers,
      wrong_answers,
    } = req.body;
    if (!set_id) {
      return res.status(400).json({ success: false, message: 'set_id is required' });
    }
    const set = await getAccessibleSet(req.user.id, set_id);
    if (!set) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not shared with you' });
    }

    const values = [
      Number(total_cards) || 0,
      Number(learned_cards) || 0,
      Number(correct_answers) || 0,
      Number(wrong_answers) || 0,
    ];
    await pool.query(
      `INSERT INTO study_progress
         (user_id, set_id, total_cards, learned_cards, correct_answers, wrong_answers, last_studied_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE
         total_cards = VALUES(total_cards),
         learned_cards = VALUES(learned_cards),
         correct_answers = VALUES(correct_answers),
         wrong_answers = VALUES(wrong_answers),
         last_studied_at = NOW()`,
      [req.user.id, set_id, ...values]
    );
    await pool.query(
      `INSERT INTO study_sessions
         (user_id, set_id, total_cards, learned_cards, correct_answers, wrong_answers)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.user.id, set_id, ...values]
    );

    const [rows] = await pool.query(
      'SELECT * FROM study_progress WHERE user_id = ? AND set_id = ?',
      [req.user.id, set_id]
    );
    return res.json({ success: true, message: 'Study progress saved', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Save progress failed', error: error.message });
  }
};

const getProgressBySetId = async (req, res) => {
  try {
    const set = await getAccessibleSet(req.user.id, req.params.setId);
    if (!set) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not shared with you' });
    }
    const [rows] = await pool.query(
      'SELECT * FROM study_progress WHERE user_id = ? AND set_id = ?',
      [req.user.id, req.params.setId]
    );
    return res.json({
      success: true,
      message: 'Study progress fetched',
      data: rows[0] || null,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch progress failed', error: error.message });
  }
};

const saveCardReview = async (req, res) => {
  try {
    const cardId = Number(req.body.card_id);
    const rating = req.body.rating;
    if (!cardId || !['forgotten', 'learning', 'remembered'].includes(rating)) {
      return res.status(400).json({ success: false, message: 'card_id and a valid rating are required' });
    }
    const [cards] = await pool.query(
      'SELECT id, set_id FROM flashcards WHERE id = ? LIMIT 1',
      [cardId]
    );
    if (!cards.length) {
      return res.status(404).json({ success: false, message: 'Flashcard not found' });
    }
    const card = cards[0];
    const set = await getAccessibleSet(req.user.id, card.set_id);
    if (!set) {
      return res.status(403).json({ success: false, message: 'This flashcard is private' });
    }
    const [existingRows] = await pool.query(
      'SELECT repetitions, interval_days FROM card_reviews WHERE user_id = ? AND card_id = ?',
      [req.user.id, cardId]
    );
    const existing = existingRows[0] || { repetitions: 0, interval_days: 0 };
    let repetitions = existing.repetitions;
    let intervalDays;
    if (rating === 'forgotten') {
      repetitions = 0;
      intervalDays = 1;
    } else if (rating === 'learning') {
      repetitions += 1;
      intervalDays = Math.max(3, existing.interval_days || 0);
    } else {
      repetitions += 1;
      intervalDays = existing.interval_days > 0
        ? Math.min(existing.interval_days * 2, 60)
        : 7;
    }

    await pool.query(
      `INSERT INTO card_reviews
         (user_id, card_id, set_id, rating, repetitions, interval_days, next_review_at, last_reviewed_at)
       VALUES (?, ?, ?, ?, ?, ?, TIMESTAMPADD(DAY, ?, NOW()), NOW())
       ON DUPLICATE KEY UPDATE
         rating = VALUES(rating),
         repetitions = VALUES(repetitions),
         interval_days = VALUES(interval_days),
         next_review_at = VALUES(next_review_at),
         last_reviewed_at = NOW()`,
      [
        req.user.id,
        cardId,
        card.set_id,
        rating,
        repetitions,
        intervalDays,
        intervalDays,
      ]
    );
    const [rows] = await pool.query(
      'SELECT * FROM card_reviews WHERE user_id = ? AND card_id = ?',
      [req.user.id, cardId]
    );
    return res.json({ success: true, message: 'Card review saved', data: rows[0] });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Save card review failed', error: error.message });
  }
};

module.exports = {
  saveProgress,
  getProgressBySetId,
  saveCardReview,
};
