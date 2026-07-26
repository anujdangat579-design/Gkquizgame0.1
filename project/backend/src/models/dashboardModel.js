const db = require('../database/connection');

// One round trip for every headline dashboard number, each computed as its
// own scalar subquery so a slow count on one table can never block the
// others (Postgres plans/executes each independently). Returns raw string
// counts (bigint -> string over the wire) and a numeric total; the service
// layer is responsible for coercing these to JS numbers.
async function getStats() {
  const result = await db.query(`
    SELECT
      (SELECT COUNT(*) FROM users) AS total_users,
      (SELECT COUNT(DISTINCT user_id) FROM refresh_tokens
         WHERE revoked = FALSE AND expires_at > now()) AS active_users,
      (SELECT COUNT(*) FROM matches) AS total_matches,
      (SELECT COUNT(*) FROM matches WHERE status = 'in_progress') AS live_matches,
      (SELECT COUNT(*) FROM payments) AS total_payments,
      (SELECT COUNT(*) FROM payments WHERE status = 'PAID') AS paid_payments,
      (SELECT COALESCE(SUM(order_amount), 0) FROM payments WHERE status = 'PAID') AS total_revenue
  `);
  return result.rows[0];
}

module.exports = { getStats };
