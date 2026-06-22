const express = require('express');
const { createCard, getCardsBySetId, updateCard, deleteCard } = require('../controllers/cardController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.post('/', createCard);
router.get('/set/:setId', getCardsBySetId);
router.put('/:id', updateCard);
router.delete('/:id', deleteCard);

module.exports = router;
