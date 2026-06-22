const express = require('express');
const { chat, generateFlashcards, explain, summarizeNotes } = require('../controllers/aiController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.post('/chat', chat);
router.post('/generate-flashcards', generateFlashcards);
router.post('/explain', explain);
router.post('/summarize-notes', summarizeNotes);

module.exports = router;
