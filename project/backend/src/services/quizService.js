const matchModel = require('../models/matchModel');
const matchAnswerModel = require('../models/matchAnswerModel');
const leaderboardModel = require('../models/leaderboardModel');
const { ROLES } = require('../constants');
const cache = require('./cacheService');
const env = require('../config/env');
const { getPeriodRange } = require('../utils/periodRange');

const LEADERBOARD_CACHE_NS = 'leaderboard';
const VALID_PERIODS = ['daily', 'weekly', 'monthly', 'all_time'];

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

async function getLeaderboard(limitRaw, periodRaw) {
  const limit = Math.min(parseInt(limitRaw, 10) || 50, 200);

  // Legacy behavior, byte-identical to before `period` existed: callers that
  // don't pass ?period= keep getting the raw leaderboard_stats rows exactly
  // as they always have.
  if (!periodRaw) {
    const version = await cache.getVersion(LEADERBOARD_CACHE_NS);
    const cacheKey = `cache:${LEADERBOARD_CACHE_NS}:v${version}:${limit}`;
    return cache.wrap(cacheKey, env.cache.leaderboardTtlSeconds, () => leaderboardModel.getTop(limit));
  }

  const period = VALID_PERIODS.includes(periodRaw) ? periodRaw : 'all_time';

  // Explicit all-time still rides the pre-aggregated, version-invalidated
  // `leaderboard_stats` rollup (fast, updated incrementally after each
  // match) — just reshaped into the same unified fields the timed periods
  // use, so `score`/`accuracyPct` are always present regardless of period.
  if (period === 'all_time') {
    const version = await cache.getVersion(LEADERBOARD_CACHE_NS);
    const cacheKey = `cache:${LEADERBOARD_CACHE_NS}:v${version}:${limit}`;
    const rows = await cache.wrap(cacheKey, env.cache.leaderboardTtlSeconds, () => leaderboardModel.getTop(limit));
    return rows.map((row) => ({
      id: row.id,
      username: row.username,
      matchesPlayed: row.matches_played,
      matchesWon: row.matches_won,
      score: row.total_correct,
      totalAnswered: row.total_answered,
      accuracyPct:
        row.total_answered > 0 ? Math.round((row.total_correct / row.total_answered) * 1000) / 10 : 0,
    }));
  }

  // Daily/weekly/monthly are computed live from matches + match_answers, so
  // the cache key includes the period's own start boundary — once the
  // day/week/month rolls over the key naturally changes and stale entries
  // just expire on their TTL, no manual invalidation needed.
  const { start, end } = getPeriodRange(period);
  const cacheKey = `cache:${LEADERBOARD_CACHE_NS}:${period}:${start.toISOString()}:${limit}`;

  const rows = await cache.wrap(cacheKey, env.cache.leaderboardTtlSeconds, () =>
    leaderboardModel.getTopByPeriod({ start, end, limit })
  );

  return rows.map((row) => ({
    id: row.id,
    username: row.username,
    matchesPlayed: Number(row.matches_played),
    matchesWon: Number(row.matches_won),
    score: Number(row.score),
    totalAnswered: Number(row.total_answered),
    accuracyPct: row.accuracy_pct !== null ? Number(row.accuracy_pct) : 0,
  }));
}

async function getMyMatches(userId) {
  return matchModel.findMineByUser(userId);
}

async function getMatchDetail(matchId, requestingUser) {
  const match = await matchModel.findById(matchId);
  if (!match) throw httpError('Match not found', 404);

  const isParticipant =
    match.player_a_id === requestingUser.id || match.player_b_id === requestingUser.id;
  if (!isParticipant && requestingUser.role !== ROLES.ADMIN) {
    throw httpError('Not authorized to view this match', 403);
  }

  const answers = await matchAnswerModel.findByMatchId(matchId);
  return { match, answers };
}

module.exports = { getLeaderboard, getMyMatches, getMatchDetail };
