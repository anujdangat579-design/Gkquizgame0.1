const Redis = require('ioredis');
const env = require('./env');
const logger = require('./logger');

// Single shared connection used for caching and the matchmaking queue.
// Socket.IO's Redis adapter needs its own dedicated pub/sub connections
// (see server.js), created via redis.duplicate() rather than reusing this
// one directly — Redis connections in subscribe mode can't issue normal
// commands.
const redis = new Redis(env.redisUrl, {
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
redis.on('error', (err) => logger.error('Redis connection error', { message: err.message }));
redis.on('close', () => logger.warn('Redis: connection closed'));
redis.on('reconnecting', (delay) => logger.warn(`Redis: reconnecting in ${delay}ms`));

module.exports = redis;
