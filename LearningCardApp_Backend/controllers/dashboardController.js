const pool = require('../config/db');

const toDateKey = (value) => {
  if (!value) return '';
  if (typeof value === 'string') return value.slice(0, 10);
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
};

const shiftDateKey = (date, offset) => {
  const next = new Date(date.getFullYear(), date.getMonth(), date.getDate() + offset);
  return toDateKey(next);
};

const calculateStreak = (dateRows) => {
  const dates = new Set(dateRows.map((row) => toDateKey(row.study_date)));
  const today = new Date();
  let cursor = dates.has(shiftDateKey(today, 0)) ? 0 : -1;
  let streak = 0;
  while (dates.has(shiftDateKey(today, cursor))) {
    streak += 1;
    cursor -= 1;
  }
  return streak;
};

const buildWeeklyActivity = (rows) => {
  const valuesByDate = new Map(
    rows.map((row) => [toDateKey(row.study_date), Number(row.learned_cards) || 0])
  );
  const today = new Date();
  return Array.from({ length: 7 }, (_, index) => {
    const date = shiftDateKey(today, index - 6);
    return { date, learned_cards: valuesByDate.get(date) || 0 };
  });
};

const normalizeRecentSet = (set) => ({
  ...set,
  card_count: Number(set.card_count) || 0,
  progress_total_cards: Number(set.progress_total_cards) || 0,
  progress_learned_cards: Number(set.progress_learned_cards) || 0,
  progress_percent: Number(set.progress_percent) || 0,
});

const getDashboard = async (req, res) => {
  try {
    const userId = req.user.id;
    const [[summary]] = await pool.query(
      `SELECT
         (SELECT daily_goal FROM users WHERE id = ?) AS daily_goal,
         (SELECT COUNT(*) FROM flashcard_sets WHERE user_id = ?) AS owned_sets,
         (SELECT COUNT(*) FROM flashcard_set_shares WHERE shared_with_user_id = ?) AS shared_sets,
         (SELECT COUNT(*) FROM notes WHERE user_id = ?) AS owned_notes,
         (SELECT COUNT(*) FROM note_shares WHERE shared_with_user_id = ?) AS shared_notes,
         (SELECT COUNT(*) FROM card_reviews WHERE user_id = ? AND last_reviewed_at IS NOT NULL) AS learned_cards,
         (SELECT COUNT(*)
            FROM flashcards card
            JOIN flashcard_sets fs ON fs.id = card.set_id
            LEFT JOIN flashcard_set_shares access_share
              ON access_share.set_id = fs.id AND access_share.shared_with_user_id = ?
            LEFT JOIN card_reviews review
              ON review.card_id = card.id AND review.user_id = ?
           WHERE (fs.user_id = ? OR access_share.id IS NOT NULL
                  OR (fs.visibility = 'public' AND review.id IS NOT NULL))
             AND (review.id IS NULL OR review.next_review_at <= NOW())) AS due_cards`,
      [userId, userId, userId, userId, userId, userId, userId, userId, userId]
    );

    const [[today]] = await pool.query(
      `SELECT COUNT(*) AS sessions,
              COALESCE(SUM(learned_cards), 0) AS learned_cards,
              COALESCE(SUM(correct_answers), 0) AS correct_answers,
              COALESCE(SUM(wrong_answers), 0) AS wrong_answers
       FROM study_sessions
       WHERE user_id = ? AND DATE(studied_at) = CURDATE()`,
      [userId]
    );
    const [studyDates] = await pool.query(
      `SELECT DISTINCT DATE(studied_at) AS study_date
       FROM study_sessions
       WHERE user_id = ? AND studied_at >= DATE_SUB(CURDATE(), INTERVAL 120 DAY)
       ORDER BY study_date DESC`,
      [userId]
    );
    const [weeklyRows] = await pool.query(
      `SELECT DATE(studied_at) AS study_date,
              SUM(learned_cards) AS learned_cards
       FROM study_sessions
       WHERE user_id = ? AND studied_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(studied_at)
       ORDER BY study_date`,
      [userId]
    );
    const [recentSets] = await pool.query(
      `SELECT fs.*, owner.name AS owner_name,
              CASE WHEN fs.user_id = ? THEN 1 ELSE 0 END AS is_owner,
              CASE WHEN fs.user_id = ? THEN 'owner' ELSE 'shared' END AS access_type,
              (SELECT COUNT(*) FROM flashcards card WHERE card.set_id = fs.id) AS card_count,
              COALESCE(progress.total_cards, 0) AS progress_total_cards,
              COALESCE(progress.learned_cards, 0) AS progress_learned_cards,
              CASE
                WHEN COALESCE(progress.total_cards, 0) = 0 THEN 0
                ELSE ROUND(progress.learned_cards * 100 / progress.total_cards)
              END AS progress_percent
       FROM flashcard_sets fs
       JOIN users owner ON owner.id = fs.user_id
       LEFT JOIN flashcard_set_shares access_share
         ON access_share.set_id = fs.id AND access_share.shared_with_user_id = ?
       LEFT JOIN study_progress progress
         ON progress.set_id = fs.id AND progress.user_id = ?
       WHERE fs.user_id = ? OR access_share.id IS NOT NULL
       ORDER BY COALESCE(progress.last_studied_at, fs.updated_at) DESC
       LIMIT 6`,
      [userId, userId, userId, userId, userId]
    );

    return res.json({
      success: true,
      message: 'Dashboard fetched',
      data: {
        daily_goal: Number(summary.daily_goal) || 20,
        owned_sets: Number(summary.owned_sets) || 0,
        shared_sets: Number(summary.shared_sets) || 0,
        total_sets: (Number(summary.owned_sets) || 0) + (Number(summary.shared_sets) || 0),
        owned_notes: Number(summary.owned_notes) || 0,
        shared_notes: Number(summary.shared_notes) || 0,
        learned_cards: Number(summary.learned_cards) || 0,
        due_cards: Number(summary.due_cards) || 0,
        study_streak: calculateStreak(studyDates),
        today: {
          sessions: Number(today.sessions) || 0,
          learned_cards: Number(today.learned_cards) || 0,
          correct_answers: Number(today.correct_answers) || 0,
          wrong_answers: Number(today.wrong_answers) || 0,
        },
        weekly_activity: buildWeeklyActivity(weeklyRows),
        recent_sets: recentSets.map(normalizeRecentSet),
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Dashboard failed', error: error.message });
  }
};

const getReviewDashboard = async (req, res) => {
  try {
    const userId = req.user.id;
    const [cards] = await pool.query(
      `SELECT DISTINCT card.*, fs.title AS set_title,
              owner.name AS owner_name,
              review.id AS review_id, review.rating,
              review.next_review_at, review.last_reviewed_at,
              CASE
                WHEN review.id IS NULL OR review.rating = 'forgotten' THEN 'Chưa nhớ'
                WHEN review.rating = 'learning' THEN 'Khó'
                ELSE 'Sắp đến hạn'
              END AS category
       FROM flashcards card
       JOIN flashcard_sets fs ON fs.id = card.set_id
       JOIN users owner ON owner.id = fs.user_id
       LEFT JOIN flashcard_set_shares access_share
         ON access_share.set_id = fs.id AND access_share.shared_with_user_id = ?
       LEFT JOIN card_reviews review
         ON review.card_id = card.id AND review.user_id = ?
       WHERE (fs.user_id = ? OR access_share.id IS NOT NULL
              OR (fs.visibility = 'public' AND review.id IS NOT NULL))
         AND (review.id IS NULL OR review.next_review_at <= DATE_ADD(NOW(), INTERVAL 1 DAY))
       ORDER BY
         review_id,
         review.next_review_at ASC,
         card.updated_at DESC
       LIMIT 60`,
      [userId, userId, userId]
    );
    const [weeklyRows] = await pool.query(
      `SELECT DATE(studied_at) AS study_date,
              SUM(learned_cards) AS learned_cards
       FROM study_sessions
       WHERE user_id = ? AND studied_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(studied_at)
       ORDER BY study_date`,
      [userId]
    );
    const [studyDates] = await pool.query(
      `SELECT DISTINCT DATE(studied_at) AS study_date
       FROM study_sessions
       WHERE user_id = ? AND studied_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
       ORDER BY study_date`,
      [userId]
    );
    const weekly = buildWeeklyActivity(weeklyRows);
    return res.json({
      success: true,
      message: 'Review dashboard fetched',
      data: {
        cards,
        due_count: cards.length,
        estimated_minutes: Math.max(1, Math.ceil(cards.length * 0.65)),
        weekly_activity: weekly,
        study_dates: studyDates.map((row) => toDateKey(row.study_date)),
        study_streak: calculateStreak(studyDates),
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Review dashboard failed', error: error.message });
  }
};

module.exports = { getDashboard, getReviewDashboard };
