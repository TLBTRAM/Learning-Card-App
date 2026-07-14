const express = require('express');
const {
  getDashboard,
  getReviewDashboard,
} = require('../controllers/dashboardController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();
router.use(protect);
router.get('/', getDashboard);
router.get('/review', getReviewDashboard);

module.exports = router;
