// Manual mock for src/database/connection.js.
//
// Unlike ioredis, `pg`'s Pool doesn't eagerly connect on construction, so the
// real module wouldn't hang test startup the way the real redis module would.
// It's still mocked wherever a test needs deterministic control over
// database reachability (e.g. the /health and /ready probes) instead of
// letting `query()` actually attempt a TCP connection to the fake
// DATABASE_URL from tests/setupEnvVars.js.
module.exports = {
  query: jest.fn(async () => ({ rows: [], rowCount: 0 })),
  getClient: jest.fn(),
  pool: { on: jest.fn(), query: jest.fn(), end: jest.fn() },
};
