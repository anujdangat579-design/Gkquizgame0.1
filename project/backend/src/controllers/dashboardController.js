const dashboardService = require('../services/dashboardService');
const asyncHandler = require('../middleware/asyncHandler');

const getDashboardStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getDashboardStats();
  res.json(stats);
});

module.exports = { getDashboardStats };
