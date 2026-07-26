// Runs before the Jest test framework is set up and before any test file is
// required, so these values are already in process.env by the time
// src/config/env.js (which reads them, throwing on anything missing) loads.
// `dotenv.config()` inside env.js never overwrites an already-set variable,
// so a real .env file (if present) won't clobber these.
process.env.NODE_ENV = 'test';
process.env.PORT = '4000';
process.env.CORS_ORIGINS = 'http://localhost:5173';

// Fake but well-formed — no test ever actually reaches Postgres or Redis
// because src/config/redis.js is mocked in every test file, and every model
// that would hit the DB is mocked in the tests that exercise it.
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/gkquiz_test';
process.env.REDIS_URL = 'redis://localhost:6379/1';

process.env.JWT_ACCESS_SECRET = 'test-access-secret';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '30d';

// Generous limits so a test file's handful of requests never trips the
// rate limiter (which would otherwise make tests order-dependent/flaky).
process.env.RATE_LIMIT_WINDOW_MS = '60000';
process.env.RATE_LIMIT_MAX = '1000';
process.env.AUTH_RATE_LIMIT_MAX = '1000';

// Fake but well-formed — no test ever actually reaches Cashfree because
// cashfreeService is mocked in any test that exercises the payment flow.
process.env.CASHFREE_APP_ID = 'test-app-id';
process.env.CASHFREE_SECRET_KEY = 'test-secret-key';
process.env.CASHFREE_ENV = 'SANDBOX';
process.env.CASHFREE_WEBHOOK_SECRET = 'test-webhook-secret';
process.env.MATCH_ENTRY_FEE_AMOUNT = '10';
process.env.MATCH_ENTRY_FEE_CURRENCY = 'INR';

process.env.BODY_LIMIT = '1mb';
process.env.LOG_FORMAT = 'dev';
process.env.LOG_LEVEL = 'error'; // keep test output focused on test results, not access logs
process.env.SHUTDOWN_TIMEOUT_MS = '1000';
