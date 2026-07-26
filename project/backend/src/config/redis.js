const env = require('./env');
const logger = require('./logger');

// Redis is entirely optional. If REDIS_URL isn't set, we never construct a
// real ioredis client (which would otherwise try to connect immediately)
// and fall back to an in-memory implementation of the same interface — see
// memoryRedis.js. Every consumer (cacheService, authService's OTP flow,
// matchmakingService) talks to `redis` through that shared interface, so
// none of them need to know or care whether Redis is actually configured.
let redis;

if (env.redisEnabled) {
  const Redis = require('ioredis');

  // Single shared connection used for caching and the matchmaking queue.
  // Socket.IO's Redis adapter needs its own dedicated pub/sub connections
  // (see server.js), created via redis.duplicate() rather than reusing this
  // one directly — Redis connections in subscribe mode can't issue normal
  // commands.
  redis = new Redis(env.redisUrl, {
    // Let commands fail fast-ish and surface errors (caught by cacheService /
    // matchmakingService) instead of queueing indefinitely while disconnected.
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      // Exponential-ish backoff, capped at 5s, retried forever — Redis being
      // briefly unavailable shouldn't require restarting the process.
      return Math.min(times * 200, 5000);
    },
  });

  redis.on('connect', () => logger.info('Redis: connected'));
  redis.on('ready', () => logger.info('Redis: ready to accept commands'));
  // Just logs — ioredis already has a listener here (this one), so an
  // unreachable/misconfigured Redis never becomes an unhandled 'error'
  // event that would crash the process. Every request-path caller also
  // catches its own Redis errors and degrades gracefully.
  redis.on('error', (err) => logger.error('Redis connection error', { message: err.message }));
  redis.on('close', () => logger.warn('Redis: connection closed'));
  redis.on('reconnecting', (delay) => logger.warn(`Redis: reconnecting in ${delay}ms`));

  redis.enabled = true;
} else {
  const MemoryRedis = require('./memoryRedis');
  redis = new MemoryRedis();
  redis.enabled = false;

  logger.warn(
    'Redis: REDIS_URL not set — running with an in-memory fallback. ' +
      'Caching, OTP storage, and the matchmaking queue will work normally on a single instance, ' +
      'but will not be shared across multiple server instances or survive a restart. ' +
      'Set REDIS_URL to enable real Redis at any time.'
  );
}

module.exports = redis;
