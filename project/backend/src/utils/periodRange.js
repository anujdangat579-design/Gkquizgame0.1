// Computes the [start, end) boundary for a leaderboard period, anchored to
// the current moment in UTC. Kept as a pure function (takes `now` as an
// argument) so tests can pin the clock instead of depending on real time.
//
// - 'daily'   -> since today's UTC midnight
// - 'weekly'  -> since this ISO week's Monday, UTC midnight
// - 'monthly' -> since the 1st of the current UTC month, midnight
// - 'all_time' -> no lower bound (returns start: null)
function getPeriodRange(period, now = new Date()) {
  const end = now;

  if (period === 'all_time') {
    return { start: null, end };
  }

  if (period === 'daily') {
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    return { start, end };
  }

  if (period === 'weekly') {
    // getUTCDay(): 0 = Sunday ... 6 = Saturday. ISO weeks start Monday, so
    // Sunday needs to roll back 6 days instead of -1.
    const dayOfWeek = now.getUTCDay();
    const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - daysSinceMonday));
    return { start, end };
  }

  if (period === 'monthly') {
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    return { start, end };
  }

  throw new Error(`Unknown leaderboard period: ${period}`);
}

module.exports = { getPeriodRange };
