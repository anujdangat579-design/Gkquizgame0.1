const dashboardModel = require('../models/dashboardModel');

// "Active users" = users currently holding at least one valid (non-revoked,
// non-expired) refresh token, i.e. logged in on some device right now.
// There's no separate last-seen/heartbeat column in the schema, so a live
// session is the closest honest signal to "active" available today.
async function getDashboardStats() {
  const row = await dashboardModel.getStats();

  return {
    totalUsers: parseInt(row.total_users, 10),
    activeUsers: parseInt(row.active_users, 10),
    totalMatches: parseInt(row.total_matches, 10),
    liveMatches: parseInt(row.live_matches, 10),
    totalPayments: parseInt(row.total_payments, 10),
    paidPayments: parseInt(row.paid_payments, 10),
    totalRevenue: Number(row.total_revenue),
  };
}

module.exports = { getDashboardStats };
