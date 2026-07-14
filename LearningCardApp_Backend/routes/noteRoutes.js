const express = require('express');
const {
  createNote,
  getNotes,
  getNoteById,
  updateNote,
  deleteNote,
  shareNote,
  getNoteShares,
  revokeNoteShare,
  updateNoteVisibility,
} = require('../controllers/noteController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();
router.use(protect);

router.post('/', createNote);
router.get('/', getNotes);
router.post('/:id/share', shareNote);
router.get('/:id/shares', getNoteShares);
router.delete('/:id/shares/:userId', revokeNoteShare);
router.put('/:id/visibility', updateNoteVisibility);
router.get('/:id', getNoteById);
router.put('/:id', updateNote);
router.delete('/:id', deleteNote);

module.exports = router;
