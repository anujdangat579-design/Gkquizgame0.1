const db = require('../database/connection');

async function initForUser(userId) {
  await db.query(`INSERT INTO leaderboard_stats (user_id) VALUES ($1) ON CONFLICT DO NOTHING`, [
    userId,
  ]);
}

async function upsertAfterMatch({ userId, won, correct, total }) {
  await db.query(
    `INSERT INTO leaderboard_stats (user_id, matches_played, matches_won, total_correct, total_answered, updated_at)
     VALUES ($1, 1, $2, $3, $4, now())
     ON CONFLICT (user_id) DO UPDATE SET
       matches_played = leaderboard_stats.matches_played + 1,
       matches_won = leaderboard_stats.matches_won + $2,
       total_correct = leaderboard_stats.total_correct + $3,
       total_answered = leaderboard_stats.total_answered + $4,
       updated_at = now()`,
    [userId, won ? 1 : 0, correct, total]
  );
}

async function getTop(limit) {
  const result = await db.query(
    `SELECT u.id, u.username, s.matches_played, s.matches_won, s.total_correct, s.total_answered
     FROM leaderboard_stats s
     JOIN users u ON u.id = s.user_id
     ORDER BY s.matches_won DESC, s.total_correct DESC
     LIMIT $1`,
    [limit]
  );
  return result.rows;
}

// Computes a leaderboard for a rolling window (daily/weekly/monthly) or the
// full all-time history, straight from `matches` + `match_answers` rather
// than the `leaderboard_stats` rollup table. This lets us rank by both
// score (total correct answers in the window) and accuracy, which the
// cumulative `leaderboard_stats` table doesn't track per-period.
//
// Only completed matches count, anchored on `completed_at` so a match that
// straddles midnight/week/month boundaries is attributed to the period it
// finished in.
async function getTopByPeriod({ start, end, limit }) {
  const params = [end];
  let dateClause = 'm.completed_at <= $1';
  if (start) {
    params.push(start);
    dateClause += ` AND m.completed_at >= $${params.length}`;
  }
  params.push(limit);

  const result = await db.query(
    `SELECT
       u.id,
       u.username,
       COUNT(DISTINCT m.id) AS matches_played,
       COUNT(DISTINCT m.id) FILTER (WHERE m.winner_id = u.id) AS matches_won,
       COALESCE(SUM(CASE WHEN ma.is_correct THEN 1 ELSE 0 END), 0) AS score,
       COUNT(ma.id) AS total_answered,
       ROUND(
         COALESCE(SUM(CASE WHEN ma.is_correct THEN 1 ELSE 0 END), 0)::numeric
         / NULLIF(COUNT(ma.id), 0) * 100,
         1
       ) AS accuracy_pct
     FROM users u
     JOIN matches m ON (m.player_a_id = u.id OR m.player_b_id = u.id) AND m.status = 'completed'
     JOIN match_answers ma ON ma.match_id = m.id AND ma.user_id = u.id
     WHERE ${dateClause}
     GROUP BY u.id, u.username
     ORDER BY score DESC, accuracy_pct DESC NULLS LAST, matches_won DESC
     LIMIT $${params.length}`,
    params
  );
  return result.rows;
}

module.exports = { initForUser, upsertAfterMatch, getTop, getTopByPeriod };
