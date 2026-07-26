module.exports = {
  testEnvironment: 'node',
  // Sets required env vars (JWT secrets, DATABASE_URL, REDIS_URL, etc.) before
  // any test file (and therefore src/config/env.js) loads.
  setupFiles: ['<rootDir>/tests/setupEnvVars.js'],
  testMatch: ['**/tests/**/*.test.js'],
  verbose: true,
  testTimeout: 15000,
  // express-rate-limit's in-memory store keeps a background cleanup timer
  // alive; nothing in this app needs it to survive past the test run, so
  // force-exit rather than have Jest hang waiting on it.
  forceExit: true,
};
