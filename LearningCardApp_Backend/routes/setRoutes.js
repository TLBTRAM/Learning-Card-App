const express = require('express');
const { createSet, getSets, getSetById, updateSet, deleteSet } = require('../controllers/setController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.post('/', createSet);
router.get('/', getSets);
router.get('/:id', getSetById);
router.put('/:id', updateSet);
router.delete('/:id', deleteSet);

module.exports = router;
