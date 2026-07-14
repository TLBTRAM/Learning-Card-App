const pool = require('../config/db');
const {
  getAccessibleSet,
  getOwnedSet,
} = require('../utils/accessControl');

const setSelect = `
  SELECT fs.*, owner.name AS owner_name,
         CASE WHEN fs.user_id = ? THEN 1 ELSE 0 END AS is_owner,
         CASE WHEN fs.user_id = ? THEN 'owner' ELSE 'shared' END AS access_type,
         (SELECT COUNT(*) FROM flashcards card WHERE card.set_id = fs.id) AS card_count,
         (SELECT COUNT(*) FROM flashcard_set_shares shared WHERE shared.set_id = fs.id) AS share_count,
         COALESCE(progress.total_cards, 0) AS progress_total_cards,
         COALESCE(progress.learned_cards, 0) AS progress_learned_cards,
         COALESCE(progress.correct_answers, 0) AS progress_correct_answers,
         COALESCE(progress.wrong_answers, 0) AS progress_wrong_answers,
         progress.last_studied_at,
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
`;

const normalizeSetNumbers = (set) => ({
  ...set,
  card_count: Number(set.card_count) || 0,
  share_count: Number(set.share_count) || 0,
  progress_total_cards: Number(set.progress_total_cards) || 0,
  progress_learned_cards: Number(set.progress_learned_cards) || 0,
  progress_correct_answers: Number(set.progress_correct_answers) || 0,
  progress_wrong_answers: Number(set.progress_wrong_answers) || 0,
  progress_percent: Number(set.progress_percent) || 0,
});

const createSet = async (req, res) => {
  try {
    const { title, description, color } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }

    const [result] = await pool.query(
      `INSERT INTO flashcard_sets
         (user_id, title, description, color, visibility)
       VALUES (?, ?, ?, ?, 'private')`,
      [req.user.id, title.trim(), description || '', color || '#17233C']
    );
    const created = await getAccessibleSet(req.user.id, result.insertId);
    return res.status(201).json({
      success: true,
      message: 'Flashcard set created',
      data: { ...created, card_count: 0, share_count: 0, progress_percent: 0 },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create set failed', error: error.message });
  }
};

const getSets = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `${setSelect} ORDER BY fs.updated_at DESC`,
      [req.user.id, req.user.id, req.user.id, req.user.id, req.user.id]
    );
    return res.json({
      success: true,
      message: 'Flashcard sets fetched',
      data: rows.map(normalizeSetNumbers),
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch sets failed', error: error.message });
  }
};

const getSetById = async (req, res) => {
  try {
    const set = await getAccessibleSet(req.user.id, req.params.id);
    if (!set) {
      return res.status(404).json({ success: false, message: 'Flashcard set not found or not shared with you' });
    }
    const [[counts]] = await pool.query(
      `SELECT
         (SELECT COUNT(*) FROM flashcards WHERE set_id = ?) AS card_count,
         (SELECT COUNT(*) FROM flashcard_set_shares WHERE set_id = ?) AS share_count`,
      [set.id, set.id]
    );
    return res.json({ success: true, message: 'Flashcard set fetched', data: { ...set, ...counts } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch set failed', error: error.message });
  }
};

const updateSet = async (req, res) => {
  try {
    const { title, description, color } = req.body;
    const owned = await getOwnedSet(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can edit this set' });
    }
    await pool.query(
      'UPDATE flashcard_sets SET title = ?, description = ?, color = ? WHERE id = ? AND user_id = ?',
      [title?.trim() || owned.title, description ?? owned.description, color || owned.color, req.params.id, req.user.id]
    );
    const updated = await getAccessibleSet(req.user.id, req.params.id);
    return res.json({ success: true, message: 'Flashcard set updated', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update set failed', error: error.message });
  }
};

const deleteSet = async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM flashcard_sets WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can delete this set' });
    }
    return res.json({ success: true, message: 'Flashcard set deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Delete set failed', error: error.message });
  }
};

const shareSet = async (req, res) => {
  try {
    const owned = await getOwnedSet(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can share this set' });
    }
    const email = req.body.email?.trim();
    if (!email) {
      return res.status(400).json({ success: false, message: 'Recipient email is required' });
    }
    const [users] = await pool.query(
      'SELECT id, name, email, avatar_url FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1',
      [email]
    );
    if (!users.length) {
      return res.status(404).json({ success: false, message: 'No account was found for this email' });
    }
    const recipient = users[0];
    if (recipient.id === req.user.id) {
      return res.status(400).json({ success: false, message: 'You already own this set' });
    }
    await pool.query(
      `INSERT INTO flashcard_set_shares
         (set_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer')
       ON DUPLICATE KEY UPDATE shared_by_user_id = VALUES(shared_by_user_id)`,
      [owned.id, recipient.id, req.user.id]
    );
    return res.status(201).json({ success: true, message: 'Flashcard set shared', data: recipient });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Share set failed', error: error.message });
  }
};

const getSetShares = async (req, res) => {
  try {
    const owned = await getOwnedSet(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can view sharing settings' });
    }
    const [rows] = await pool.query(
      `SELECT user.id, user.name, user.email, user.avatar_url,
              share.permission, share.created_at
       FROM flashcard_set_shares share
       JOIN users user ON user.id = share.shared_with_user_id
       WHERE share.set_id = ?
       ORDER BY share.created_at DESC`,
      [owned.id]
    );
    return res.json({ success: true, message: 'Set shares fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch shares failed', error: error.message });
  }
};

const revokeSetShare = async (req, res) => {
  try {
    const owned = await getOwnedSet(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can revoke access' });
    }
    await pool.query(
      'DELETE FROM flashcard_set_shares WHERE set_id = ? AND shared_with_user_id = ?',
      [owned.id, req.params.userId]
    );
    return res.json({ success: true, message: 'Set access revoked' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Revoke access failed', error: error.message });
  }
};

const updateSetVisibility = async (req, res) => {
  try {
    const visibility = req.body.visibility;
    if (!['private', 'public'].includes(visibility)) {
      return res.status(400).json({ success: false, message: 'Visibility must be private or public' });
    }
    const [result] = await pool.query(
      'UPDATE flashcard_sets SET visibility = ? WHERE id = ? AND user_id = ?',
      [visibility, req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can change visibility' });
    }
    return res.json({ success: true, message: 'Set visibility updated', data: { visibility } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update visibility failed', error: error.message });
  }
};

module.exports = {
  createSet,
  getSets,
  getSetById,
  updateSet,
  deleteSet,
  shareSet,
  getSetShares,
  revokeSetShare,
  updateSetVisibility,
};
