const pool = require('../config/db');
const {
  getAccessibleNote,
  getOwnedNote,
} = require('../utils/accessControl');

const noteSelect = `
  SELECT note.*, owner.name AS owner_name,
         CASE WHEN note.user_id = ? THEN 1 ELSE 0 END AS is_owner,
         CASE WHEN note.user_id = ? THEN 'owner' ELSE 'shared' END AS access_type,
         (SELECT COUNT(*) FROM note_shares shared WHERE shared.note_id = note.id) AS share_count
  FROM notes note
  JOIN users owner ON owner.id = note.user_id
  LEFT JOIN note_shares access_share
    ON access_share.note_id = note.id AND access_share.shared_with_user_id = ?
  WHERE note.user_id = ? OR access_share.id IS NOT NULL
`;

const createNote = async (req, res) => {
  try {
    const { title, content_text, drawing_data } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }
    const [result] = await pool.query(
      `INSERT INTO notes
         (user_id, title, content_text, drawing_data, visibility)
       VALUES (?, ?, ?, ?, 'private')`,
      [req.user.id, title.trim(), content_text || '', JSON.stringify(drawing_data || [])]
    );
    const created = await getAccessibleNote(req.user.id, result.insertId);
    return res.status(201).json({
      success: true,
      message: 'Note created',
      data: { ...created, share_count: 0 },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Create note failed', error: error.message });
  }
};

const getNotes = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `${noteSelect} ORDER BY note.updated_at DESC`,
      [req.user.id, req.user.id, req.user.id, req.user.id]
    );
    return res.json({ success: true, message: 'Notes fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch notes failed', error: error.message });
  }
};

const getNoteById = async (req, res) => {
  try {
    const note = await getAccessibleNote(req.user.id, req.params.id);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found or not shared with you' });
    }
    return res.json({ success: true, message: 'Note fetched', data: note });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch note failed', error: error.message });
  }
};

const updateNote = async (req, res) => {
  try {
    const owned = await getOwnedNote(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can edit this note' });
    }
    const { title, content_text, drawing_data } = req.body;
    await pool.query(
      `UPDATE notes
       SET title = ?, content_text = ?, drawing_data = ?
       WHERE id = ? AND user_id = ?`,
      [
        title?.trim() || owned.title,
        content_text ?? owned.content_text,
        JSON.stringify(drawing_data || []),
        req.params.id,
        req.user.id,
      ]
    );
    const updated = await getAccessibleNote(req.user.id, req.params.id);
    return res.json({ success: true, message: 'Note updated', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update note failed', error: error.message });
  }
};

const deleteNote = async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM notes WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can delete this note' });
    }
    return res.json({ success: true, message: 'Note deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Delete note failed', error: error.message });
  }
};

const shareNote = async (req, res) => {
  try {
    const owned = await getOwnedNote(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can share this note' });
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
      return res.status(400).json({ success: false, message: 'You already own this note' });
    }
    await pool.query(
      `INSERT INTO note_shares
         (note_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer')
       ON DUPLICATE KEY UPDATE shared_by_user_id = VALUES(shared_by_user_id)`,
      [owned.id, recipient.id, req.user.id]
    );
    return res.status(201).json({ success: true, message: 'Note shared', data: recipient });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Share note failed', error: error.message });
  }
};

const getNoteShares = async (req, res) => {
  try {
    const owned = await getOwnedNote(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can view sharing settings' });
    }
    const [rows] = await pool.query(
      `SELECT user.id, user.name, user.email, user.avatar_url,
              share.permission, share.created_at
       FROM note_shares share
       JOIN users user ON user.id = share.shared_with_user_id
       WHERE share.note_id = ?
       ORDER BY share.created_at DESC`,
      [owned.id]
    );
    return res.json({ success: true, message: 'Note shares fetched', data: rows });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Fetch note shares failed', error: error.message });
  }
};

const revokeNoteShare = async (req, res) => {
  try {
    const owned = await getOwnedNote(req.user.id, req.params.id);
    if (!owned) {
      return res.status(403).json({ success: false, message: 'Only the creator can revoke access' });
    }
    await pool.query(
      'DELETE FROM note_shares WHERE note_id = ? AND shared_with_user_id = ?',
      [owned.id, req.params.userId]
    );
    return res.json({ success: true, message: 'Note access revoked' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Revoke note access failed', error: error.message });
  }
};

const updateNoteVisibility = async (req, res) => {
  try {
    const visibility = req.body.visibility;
    if (!['private', 'public'].includes(visibility)) {
      return res.status(400).json({ success: false, message: 'Visibility must be private or public' });
    }
    const [result] = await pool.query(
      'UPDATE notes SET visibility = ? WHERE id = ? AND user_id = ?',
      [visibility, req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(403).json({ success: false, message: 'Only the creator can change visibility' });
    }
    return res.json({ success: true, message: 'Note visibility updated', data: { visibility } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Update note visibility failed', error: error.message });
  }
};

module.exports = {
  createNote,
  getNotes,
  getNoteById,
  updateNote,
  deleteNote,
  shareNote,
  getNoteShares,
  revokeNoteShare,
  updateNoteVisibility,
};
