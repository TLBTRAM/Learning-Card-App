const express = require('express');
const { 
  chat, 
  getSessions, 
  getSessionDetails, 
  deleteSession 
} = require('../controllers/aiController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/chat', chat);
router.get('/sessions', getSessions);
router.get('/sessions/:id', getSessionDetails);
router.delete('/sessions/:id', deleteSession);

module.exports = router;