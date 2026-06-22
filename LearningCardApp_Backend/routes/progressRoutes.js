const express = require('express');
const { saveProgress, getProgressBySetId } = require('../controllers/progressController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.post('/', saveProgress);
router.get('/:setId', getProgressBySetId);

module.exports = router;
