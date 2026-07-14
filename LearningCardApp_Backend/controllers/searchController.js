const pool = require('../config/db');

const search = async (req, res) => {
  try {
    const query = String(req.query.q || '').trim();
    if (!query) {
      return res.json({
        success: true,
        message: 'Search query is empty',
        data: { sets: [], cards: [], notes: [] },
      });
    }
    const like = `%${query.slice(0, 100)}%`;
    const userId = req.user.id;

    const [sets] = await pool.query(
      `SELECT DISTINCT fs.*, owner.name AS owner_name,
              CASE WHEN fs.user_id = ? THEN 1 ELSE 0 END AS is_owner,
              CASE
                WHEN fs.user_id = ? THEN 'owner'
                WHEN access_share.id IS NOT NULL THEN 'shared'
                ELSE 'public'
              END AS access_type,
              (SELECT COUNT(*) FROM flashcards card WHERE card.set_id = fs.id) AS card_count,
              (SELECT COUNT(*) FROM flashcard_set_shares shared WHERE shared.set_id = fs.id) AS share_count
       FROM flashcard_sets fs
       JOIN users owner ON owner.id = fs.user_id
       LEFT JOIN flashcard_set_shares access_share
         ON access_share.set_id = fs.id AND access_share.shared_with_user_id = ?
       WHERE (fs.user_id = ? OR access_share.id IS NOT NULL OR fs.visibility = 'public')
         AND (fs.title LIKE ? OR fs.description LIKE ?)
       ORDER BY fs.updated_at DESC
       LIMIT 20`,
      [userId, userId, userId, userId, like, like]
    );

    const [cards] = await pool.query(
      `SELECT DISTINCT card.*, fs.title AS set_title,
              fs.description AS set_description, fs.color AS set_color,
              fs.user_id AS set_user_id, fs.visibility AS set_visibility,
              owner.name AS owner_name,
              CASE WHEN fs.user_id = ? THEN 1 ELSE 0 END AS is_owner,
              (SELECT COUNT(*) FROM flashcards set_card WHERE set_card.set_id = fs.id) AS set_card_count
       FROM flashcards card
       JOIN flashcard_sets fs ON fs.id = card.set_id
       JOIN users owner ON owner.id = fs.user_id
       LEFT JOIN flashcard_set_shares access_share
         ON access_share.set_id = fs.id AND access_share.shared_with_user_id = ?
       WHERE (fs.user_id = ? OR access_share.id IS NOT NULL OR fs.visibility = 'public')
         AND (card.front LIKE ? OR card.back LIKE ? OR card.example LIKE ?)
       ORDER BY card.updated_at DESC
       LIMIT 30`,
      [userId, userId, userId, like, like, like]
    );

    const [notes] = await pool.query(
      `SELECT DISTINCT note.*, owner.name AS owner_name,
              CASE WHEN note.user_id = ? THEN 1 ELSE 0 END AS is_owner,
              CASE
                WHEN note.user_id = ? THEN 'owner'
                WHEN access_share.id IS NOT NULL THEN 'shared'
                ELSE 'public'
              END AS access_type,
              (SELECT COUNT(*) FROM note_shares shared WHERE shared.note_id = note.id) AS share_count
       FROM notes note
       JOIN users owner ON owner.id = note.user_id
       LEFT JOIN note_shares access_share
         ON access_share.note_id = note.id AND access_share.shared_with_user_id = ?
       WHERE (note.user_id = ? OR access_share.id IS NOT NULL OR note.visibility = 'public')
         AND (note.title LIKE ? OR note.content_text LIKE ?)
       ORDER BY note.updated_at DESC
       LIMIT 20`,
      [userId, userId, userId, userId, like, like]
    );

    return res.json({
      success: true,
      message: 'Search completed',
      data: { sets, cards, notes },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Search failed', error: error.message });
  }
};

module.exports = { search };
