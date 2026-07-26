// Manual mock for src/services/cacheService.js.
//
// `wrap` always calls straight through to `loader`, so tests get fresh data
// from the (mocked) model every call instead of a stale cached value from a
// previous test in the same file — caching behavior itself isn't what these
// API tests are meant to verify.
module.exports = {
  getVersion: jest.fn(async () => '0'),
  bumpVersion: jest.fn(async () => {}),
  wrap: jest.fn(async (key, ttlSeconds, loader) => loader()),
};
