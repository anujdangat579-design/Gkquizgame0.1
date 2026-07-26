// Redis-backed matchmaking queue, keyed by "category:difficulty:questionCount".
// Moving this off the in-process Map (the previous implementation) means:
//   - matchmaking state survives a restart/redeploy instead of stranding
//     whoever was mid-queue
//   - it works correctly if this service ever runs as more than one Node
//     instance (e.g. Render autoscaling) — the queue is shared, not per-process
const redis = require('../config/redis');
const logger = require('../config/logger');

// Safety-net TTL on the per-user queue markers. If a process crashes between
// "queued" and a clean dequeue/match, the entry expires on its own instead
// of leaving the user stuck forever unable to re-queue.
const ENTRY_TTL_SECONDS = 5 * 60;

function queueKey({ category, difficulty, questionCount }) {
  return `${category || 'any'}:${difficulty}:${questionCount}`;
}

// Atomically: reject the join if this user is already queued somewhere,
// otherwise push their entry onto the queue list and, if that brings the
// queue to 2+ waiting players, pop the first two off and hand them back as
// a pair. Running this as a single Lua script means the "check queued ->
// push -> maybe pop two" sequence can't race with a concurrent join (from
// another socket event, or another server instance sharing this Redis) and
// accidentally double-queue or double-pair a user.
redis.defineCommand('mmEnqueue', {
  numberOfKeys: 3,
  lua: `
    local queueListKey = KEYS[1]
    local userQueueKeyKey = KEYS[2]
    local userEntryKey = KEYS[3]
    local entryJson = ARGV[1]
    local qkey = ARGV[2]
    local ttl = tonumber(ARGV[3])

    if redis.call('EXISTS', userQueueKeyKey) == 1 then
      return 0
    end

    redis.call('RPUSH', queueListKey, entryJson)
    redis.call('SET', userQueueKeyKey, qkey, 'EX', ttl)
    redis.call('SET', userEntryKey, entryJson, 'EX', ttl)

    if redis.call('LLEN', queueListKey) >= 2 then
      local a = redis.call('LPOP', queueListKey)
      local b = redis.call('LPOP', queueListKey)
      local ea = cjson.decode(a)
      local eb = cjson.decode(b)
      redis.call('DEL', 'mm:userQueueKey:' .. ea.userId, 'mm:userEntry:' .. ea.userId)
      redis.call('DEL', 'mm:userQueueKey:' .. eb.userId, 'mm:userEntry:' .. eb.userId)
      return {a, b}
    end

    return 1
  `,
});

async function enqueue(criteria, entry) {
  const key = queueKey(criteria);

  let result;
  try {
    result = await redis.mmEnqueue(
      `mm:queue:${key}`,
      `mm:userQueueKey:${entry.userId}`,
      `mm:userEntry:${entry.userId}`,
      JSON.stringify(entry),
      key,
      ENTRY_TTL_SECONDS
    );
  } catch (err) {
    logger.error('matchmaking: enqueue failed', { message: err.message, userId: entry.userId });
    throw err;
  }

  if (Array.isArray(result)) {
    const [playerA, playerB] = result.map((s) => JSON.parse(s));
    return { playerA, playerB, criteria };
  }
  if (result === 0) {
    return 'ALREADY_QUEUED'; // rejected — this user already has an active queue entry, nothing was added
  }
  return null; // added successfully, now waiting for an opponent
}

async function dequeue(userId) {
  try {
    const qkey = await redis.get(`mm:userQueueKey:${userId}`);
    if (!qkey) return false;

    const entry = await redis.get(`mm:userEntry:${userId}`);
    if (entry) {
      await redis.lrem(`mm:queue:${qkey}`, 0, entry);
    }
    await redis.del(`mm:userQueueKey:${userId}`, `mm:userEntry:${userId}`);
    return true;
  } catch (err) {
    logger.error('matchmaking: dequeue failed', { message: err.message, userId });
    return false;
  }
}

module.exports = { enqueue, dequeue, queueKey };
