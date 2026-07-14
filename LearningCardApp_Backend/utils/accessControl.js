const pool = require('../config/db');

const getAccessibleSet = async (userId, setId) => {
  const [rows] = await pool.query(
    `SELECT fs.*, owner.name AS owner_name,
            CASE WHEN fs.user_id = ? THEN 1 ELSE 0 END AS is_owner,
            CASE
              WHEN fs.user_id = ? THEN 'owner'
              WHEN share.id IS NOT NULL THEN 'shared'
              ELSE 'public'
            END AS access_type
     FROM flashcard_sets fs
     JOIN users owner ON owner.id = fs.user_id
     LEFT JOIN flashcard_set_shares share
       ON share.set_id = fs.id AND share.shared_with_user_id = ?
     WHERE fs.id = ?
       AND (fs.user_id = ? OR share.id IS NOT NULL OR fs.visibility = 'public')
     LIMIT 1`,
    [userId, userId, userId, setId, userId]
  );
  return rows[0] || null;
};

const getOwnedSet = async (userId, setId) => {
  const [rows] = await pool.query(
    'SELECT * FROM flashcard_sets WHERE id = ? AND user_id = ? LIMIT 1',
    [setId, userId]
  );
  return rows[0] || null;
};

const getAccessibleNote = async (userId, noteId) => {
  const [rows] = await pool.query(
    `SELECT note.*, owner.name AS owner_name,
            CASE WHEN note.user_id = ? THEN 1 ELSE 0 END AS is_owner,
            CASE
              WHEN note.user_id = ? THEN 'owner'
              WHEN share.id IS NOT NULL THEN 'shared'
              ELSE 'public'
            END AS access_type
     FROM notes note
     JOIN users owner ON owner.id = note.user_id
     LEFT JOIN note_shares share
       ON share.note_id = note.id AND share.shared_with_user_id = ?
     WHERE note.id = ?
       AND (note.user_id = ? OR share.id IS NOT NULL OR note.visibility = 'public')
     LIMIT 1`,
    [userId, userId, userId, noteId, userId]
  );
  return rows[0] || null;
};

const getOwnedNote = async (userId, noteId) => {
  const [rows] = await pool.query(
    'SELECT * FROM notes WHERE id = ? AND user_id = ? LIMIT 1',
    [noteId, userId]
  );
  return rows[0] || null;
};

module.exports = {
  getAccessibleSet,
  getOwnedSet,
  getAccessibleNote,
  getOwnedNote,
};
