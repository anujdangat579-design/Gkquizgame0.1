// In-memory stand-in for the ioredis client, used whenever REDIS_URL isn't
// set. It implements only the subset of the ioredis API this codebase
// actually calls (get/set/del/incr/ping/quit/duplicate/on/defineCommand),
// with the same call signatures and return shapes, so cacheService,
// authService's OTP flow, and matchmakingService all work completely
// unmodified against it.
//
// Trade-offs vs real Redis (acceptable for the "no Redis configured" case
// this exists for):
//   - Not shared across processes/instances — each Node process has its own
//     store. Fine for a single Render instance; if REDIS_URL is set later,
//     the real client takes over and this is never used.
//   - Not persisted — cache, OTP codes, and the matchmaking queue reset on
//     restart/redeploy, same as they would for a fresh Redis instance with
//     no data.
//   - TTLs are checked lazily (on read) rather than actively swept, which
//     is fine for values this small and short-lived.

class MemoryRedis {
  constructor() {
    // key -> { type: 'string' | 'list', value, expiresAt: number|null }
    this.store = new Map();
    this.enabled = false; // set explicitly so callers can branch on it without a network round-trip
  }

  _isExpired(entry) {
    return entry.expiresAt !== null && entry.expiresAt <= Date.now();
  }

  _read(key) {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (this._isExpired(entry)) {
      this.store.delete(key);
      return null;
    }
    return entry;
  }

  // --- Strings ---------------------------------------------------------

  async get(key) {
    const entry = this._read(key);
    return entry && entry.type === 'string' ? entry.value : null;
  }

  // Supports the two call shapes used in this codebase:
  //   redis.set(key, value)
  //   redis.set(key, value, 'EX', ttlSeconds)
  async set(key, value, mode, ttlSeconds) {
    let expiresAt = null;
    if (mode === 'EX' && ttlSeconds) {
      expiresAt = Date.now() + Number(ttlSeconds) * 1000;
    }
    this.store.set(key, { type: 'string', value: String(value), expiresAt });
    return 'OK';
  }

  async incr(key) {
    const entry = this._read(key);
    const next = (entry && entry.type === 'string' ? parseInt(entry.value, 10) || 0 : 0) + 1;
    const expiresAt = entry ? entry.expiresAt : null;
    this.store.set(key, { type: 'string', value: String(next), expiresAt });
    return next;
  }

  async del(...keys) {
    const flat = keys.flat();
    let count = 0;
    for (const key of flat) {
      if (this.store.delete(key)) count += 1;
    }
    return count;
  }

  // --- Lists (just enough for matchmakingService's queue) ---------------

  _list(key) {
    const entry = this._read(key);
    if (entry && entry.type === 'list') return entry.value;
    return null;
  }

  async rpush(key, value) {
    let list = this._list(key);
    if (!list) {
      list = [];
      this.store.set(key, { type: 'list', value: list, expiresAt: null });
    }
    list.push(value);
    return list.length;
  }

  async lpop(key) {
    const list = this._list(key);
    if (!list || list.length === 0) return null;
    const value = list.shift();
    if (list.length === 0) this.store.delete(key);
    return value;
  }

  async llen(key) {
    const list = this._list(key);
    return list ? list.length : 0;
  }

  async lrem(key, count, value) {
    const list = this._list(key);
    if (!list) return 0;
    const before = list.length;
    // count === 0 (the only usage in this codebase) removes all matches.
    const filtered = list.filter((item) => item !== value);
    const removed = before - filtered.length;
    if (filtered.length === 0) {
      this.store.delete(key);
    } else {
      this.store.set(key, { type: 'list', value: filtered, expiresAt: null });
    }
    return removed;
  }

  // --- Connection-shaped no-ops ------------------------------------------

  async ping() {
    return 'PONG';
  }

  async quit() {
    this.store.clear();
    return 'OK';
  }

  duplicate() {
    // Real ioredis duplicate() opens a second connection to the same
    // server (same data). Nothing in this app calls duplicate() when
    // running in memory-fallback mode (server.js skips the Socket.IO
    // Redis adapter entirely in that case), but return a working instance
    // just in case, sharing the same underlying store.
    const copy = new MemoryRedis();
    copy.store = this.store;
    return copy;
  }

  on() {
    // No connection events to emit — always "connected".
    return this;
  }

  // Mimics ioredis's defineCommand(name, { lua }) for Lua scripts by
  // attaching a hand-written JS equivalent instead of actually running Lua.
  // Only "mmEnqueue" (matchmakingService's atomic enqueue-and-pair script)
  // is used in this codebase. Because this runs synchronously with no
  // `await` in the middle, it's atomic within the Node event loop — the
  // same guarantee the real Lua script provides against concurrent joins.
  defineCommand(name) {
    if (name !== 'mmEnqueue') return; // nothing else defines a custom command today

    this.mmEnqueue = async (queueListKey, userQueueKeyKey, userEntryKey, entryJson, qkey, ttl) => {
      if (this._read(userQueueKeyKey)) return 0;

      await this.rpush(queueListKey, entryJson);
      await this.set(userQueueKeyKey, qkey, 'EX', ttl);
      await this.set(userEntryKey, entryJson, 'EX', ttl);

      if ((await this.llen(queueListKey)) >= 2) {
        const a = await this.lpop(queueListKey);
        const b = await this.lpop(queueListKey);
        const ea = JSON.parse(a);
        const eb = JSON.parse(b);
        await this.del(`mm:userQueueKey:${ea.userId}`, `mm:userEntry:${ea.userId}`);
        await this.del(`mm:userQueueKey:${eb.userId}`, `mm:userEntry:${eb.userId}`);
        return [a, b];
      }

      return 1;
    };
  }
}

module.exports = MemoryRedis;
