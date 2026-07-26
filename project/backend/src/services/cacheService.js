const redis = require('../config/redis');
const logger = require('../config/logger');

// Version-based cache invalidation: instead of tracking/deleting every
// individual cache key for a resource (which needs SCAN or a key registry),
// each cache key embeds a namespace "version" number. Bumping the version
// makes every previously-cached key for that namespace instantly
// unreachable (they're never looked up again) and they simply expire on
// their own TTL. Cheap, race-free, and needs no key enumeration.
async function getVersion(namespace) {
  try {
    const v = await redis.get(`cache:version:${namespace}`);
    return v || '0';
  } catch (err) {
    logger.warn(`cache: getVersion(${namespace}) failed, bypassing cache`, { message: err.message });
    return '0';
  }
}

async function bumpVersion(namespace) {
  try {
    await redis.incr(`cache:version:${namespace}`);
  } catch (err) {
    logger.warn(`cache: bumpVersion(${namespace}) failed`, { message: err.message });
  }
}

// Cache-aside read: return the cached value if present, otherwise call
// `loader`, cache its result for `ttlSeconds`, and return it.
//
// Any Redis failure (read or write) is logged and swallowed rather than
// thrown — `loader` (the real DB query) always runs as the source of truth,
// so a Redis outage degrades performance, not availability.
async function wrap(key, ttlSeconds, loader) {
  try {
    const cached = await redis.get(key);
    if (cached !== null) return JSON.parse(cached);
  } catch (err) {
    logger.warn(`cache: read failed for "${key}"`, { message: err.message });
  }

  const fresh = await loader();

  try {
    await redis.set(key, JSON.stringify(fresh), 'EX', ttlSeconds);
  } catch (err) {
    logger.warn(`cache: write failed for "${key}"`, { message: err.message });
  }

  return fresh;
}

module.exports = { getVersion, bumpVersion, wrap };
