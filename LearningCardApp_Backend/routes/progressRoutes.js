const express = require('express');
const {
  saveProgress,
  getProgressBySetId,
  saveCardReview,
} = require('../controllers/progressController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();
router.use(protect);

router.post('/', saveProgress);
router.post('/review', saveCardReview);
router.get('/:setId', getProgressBySetId);

module.exports = router;
