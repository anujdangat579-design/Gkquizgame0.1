// Manual mock for src/config/redis.js.
//
// The real module opens an eager TCP connection to Redis the moment it's
// required (ioredis connects on instantiation, with infinite retry) — which
// would make any test that requires src/app.js hang or spam connection
// errors. Every test file mocks this module with `jest.mock('../src/config/redis')`
// so that never happens.
//
// This fake is a small in-memory stand-in that implements just what
// cacheService and app.js's /health handler use, so real (unmocked)
// cacheService code still works correctly against it in tests that don't
// need to mock caching away entirely.
function createRedisMock() {
  const store = new Map();

  return {
    // Tests set REDIS_URL in setupEnvVars.js, so the real module would
    // construct an enabled client — this mock mirrors that by default.
    // Individual tests can override (`redis.enabled = false`) to exercise
    // the disabled/in-memory-fallback path.
    enabled: true,
    get: jest.fn(async (key) => (store.has(key) ? store.get(key) : null)),
    set: jest.fn(async (key, value) => {
      store.set(key, value);
      return 'OK';
    }),
    incr: jest.fn(async (key) => {
      const next = (parseInt(store.get(key), 10) || 0) + 1;
      store.set(key, String(next));
      return next;
    }),
    del: jest.fn(async (key) => {
      const existed = store.has(key);
      store.delete(key);
      return existed ? 1 : 0;
    }),
    ping: jest.fn(async () => 'PONG'),
    quit: jest.fn(async () => 'OK'),
    duplicate: jest.fn(() => createRedisMock()),
    on: jest.fn(),
  };
}

module.exports = createRedisMock();
