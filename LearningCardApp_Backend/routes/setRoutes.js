const express = require('express');
const {
  createSet,
  getSets,
  getSetById,
  updateSet,
  deleteSet,
  shareSet,
  getSetShares,
  revokeSetShare,
  updateSetVisibility,
} = require('../controllers/setController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();
router.use(protect);

router.post('/', createSet);
router.get('/', getSets);
router.post('/:id/share', shareSet);
router.get('/:id/shares', getSetShares);
router.delete('/:id/shares/:userId', revokeSetShare);
router.put('/:id/visibility', updateSetVisibility);
router.get('/:id', getSetById);
router.put('/:id', updateSet);
router.delete('/:id', deleteSet);

module.exports = router;
