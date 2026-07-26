const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const hpp = require('hpp');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const env = require('./config/env');
const logger = require('./config/logger');
const redis = require('./config/redis');
const db = require('./database/connection');
const swaggerSpec = require('./config/swagger');
const { apiLimiter } = require('./middleware/rateLimit');
const { notFound, errorHandler } = require('./middleware/errorHandler');
const asyncHandler = require('./middleware/asyncHandler');

const authRoutes = require('./routes/authRoutes');
const questionRoutes = require('./routes/questionRoutes');
const quizRoutes = require('./routes/quizRoutes');
const auditLogRoutes = require('./routes/auditLogRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();

// --- Core hardening -------------------------------------------------------
app.disable('x-powered-by'); // belt-and-braces on top of helmet.hidePoweredBy()
app.set('trust proxy', 1); // needed on Render so req.ip / rate-limiter see the real client IP

// Strict CSP for the API itself: this is a pure JSON API with no
// server-rendered HTML, so nothing should ever load a script, style, frame,
// or plugin in a browser context — default-src 'none' blocks all of it.
// /api-docs (Swagger UI) needs a more permissive policy to render; that's
// applied separately, scoped to just that route, further down.
const apiCspDirectives = {
  defaultSrc: ["'none'"],
  frameAncestors: ["'none'"], // clickjacking protection (belt-and-braces on top of X-Frame-Options)
  baseUri: ["'none'"],
  formAction: ["'none'"],
};

app.use(
  helmet({
    // Cross-Origin-Resource-Policy defaults to "same-origin", which would
    // block the frontend (a different origin) from loading e.g. images or
    // JSON served directly by this API. "cross-origin" is safe here since
    // access control is already enforced by the CORS whitelist below.
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    contentSecurityPolicy: { directives: apiCspDirectives },
    // Controls the Referer header sent by browsers on outbound requests
    // triggered from this API's responses (e.g. a link in an error page).
    // "no-referrer" leaks nothing, which is the safest option for a JSON API.
    referrerPolicy: { policy: 'no-referrer' },
    // The legacy X-XSS-Protection browser filter is deliberately left at helmet's
    // default of "0" (disabled) rather than "1; mode=block": modern browsers have
    // removed the filter entirely, and on the (very old) browsers that still honor
    // it, the header itself has been used as an XSS vector. CSP above is the actual,
    // current mitigation for injected scripts. See https://github.com/helmetjs/helmet#reference.
  })
);

// Permissions-Policy isn't set by Helmet itself (dropped after the old
// Feature-Policy header's spec churn), so it's set explicitly here. This is a
// JSON API with no browser-facing UI of its own, so every powerful browser
// feature is locked down to "allow nowhere" — nothing on this origin ever
// needs a camera, microphone, geolocation, etc. Swagger UI at /api-docs
// doesn't use any of these either, so this applies globally.
app.use((req, res, next) => {
  res.setHeader(
    'Permissions-Policy',
    [
      'accelerometer=()',
      'camera=()',
      'geolocation=()',
      'gyroscope=()',
      'magnetometer=()',
      'microphone=()',
      'payment=()',
      'usb=()',
      'interest-cohort=()',
    ].join(', ')
  );
  next();
});

// --- CORS (env-driven whitelist) ------------------------------------------
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow non-browser requests (no origin header, e.g. curl/server-to-server)
      // and any origin present in the CORS_ORIGINS whitelist.
      if (!origin || env.corsOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  })
);

// --- Perf -------------------------------------------------------------
app.use(compression());

// --- Logging ------------------------------------------------------------
// morgan formats each HTTP request into a line; winston takes it from there
// (console + logs/combined.log). Skip the health check so uptime pings
// don't flood the logs.
app.use(
  morgan(env.logFormat, {
    stream: logger.stream,
    skip: (req) => req.path === '/health' || req.path === '/ready' || req.path === '/live',
  })
);

// --- Health / readiness / liveness checks -----------------------------
// Registered before body parsing and rate limiting so probes (Kubernetes,
// Render, uptime monitors) always get a fast, unlimited response even if
// the app is otherwise under heavy load or misconfigured.
async function checkDatabase() {
  try {
    await db.query('SELECT 1');
    return 'ok';
  } catch (err) {
    return 'unreachable';
  }
}

async function checkRedis() {
  if (!redis.enabled) return 'disabled'; // REDIS_URL not set — running on the in-memory fallback
  try {
    await redis.ping();
    return 'ok';
  } catch (err) {
    return 'unreachable';
  }
}

/**
 * @openapi
 * /health:
 *   get:
 *     tags: [Health]
 *     summary: Detailed service health check
 *     description: >
 *       Reports process uptime plus current database and Redis reachability.
 *       Always returns 200 (even if a dependency is unreachable) — check the
 *       `database`/`redis` fields for actual status. Excluded from access logs
 *       and not rate-limited. For automated pass/fail checks, use /ready or /live instead.
 *     security: []
 *     responses:
 *       200:
 *         description: Process is up; see `database`/`redis` for dependency status
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status: { type: string, example: ok }
 *                 timestamp: { type: string, format: date-time }
 *                 uptimeSeconds: { type: integer, example: 3600 }
 *                 environment: { type: string, example: production }
 *                 database: { type: string, enum: [ok, unreachable] }
 *                 redis: { type: string, enum: [ok, unreachable, disabled] }
 */
app.get(
  '/health',
  asyncHandler(async (req, res) => {
    const [database, redisStatus] = await Promise.all([checkDatabase(), checkRedis()]);

    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.round(process.uptime()),
      environment: env.nodeEnv,
      database,
      redis: redisStatus,
    });
  })
);

/**
 * @openapi
 * /ready:
 *   get:
 *     tags: [Health]
 *     summary: Readiness probe
 *     description: >
 *       Checks whether this instance can actually serve traffic. The database
 *       must be reachable. Redis is optional — 'disabled' (REDIS_URL not set)
 *       counts as healthy, but a configured Redis that's unreachable does not.
 *       Returns 503 if the instance isn't ready, so an orchestrator can stop
 *       routing requests here without restarting the process. Excluded from
 *       access logs and not rate-limited.
 *     security: []
 *     responses:
 *       200:
 *         description: Ready — database and Redis are both reachable
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status: { type: string, example: ok }
 *                 timestamp: { type: string, format: date-time }
 *                 database: { type: string, enum: [ok, unreachable] }
 *                 redis: { type: string, enum: [ok, unreachable, disabled] }
 *       503:
 *         description: Not ready — database and/or Redis is unreachable
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status: { type: string, example: unavailable }
 *                 timestamp: { type: string, format: date-time }
 *                 database: { type: string, enum: [ok, unreachable] }
 *                 redis: { type: string, enum: [ok, unreachable, disabled] }
 */
app.get(
  '/ready',
  asyncHandler(async (req, res) => {
    const [database, redisStatus] = await Promise.all([checkDatabase(), checkRedis()]);
    // Redis is optional: 'disabled' (REDIS_URL not set) is a healthy state.
    // Only an actually-configured-but-unreachable Redis should fail readiness.
    const ready = database === 'ok' && redisStatus !== 'unreachable';

    res.status(ready ? 200 : 503).json({
      status: ready ? 'ok' : 'unavailable',
      timestamp: new Date().toISOString(),
      database,
      redis: redisStatus,
    });
  })
);

/**
 * @openapi
 * /live:
 *   get:
 *     tags: [Health]
 *     summary: Liveness probe
 *     description: >
 *       Confirms the process itself is up and able to respond to requests.
 *       Deliberately does not check the database or Redis — a dependency
 *       outage should surface via /ready, not cause an orchestrator to kill
 *       and restart a perfectly healthy process. Excluded from access logs
 *       and not rate-limited.
 *     security: []
 *     responses:
 *       200:
 *         description: Process is alive
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status: { type: string, example: ok }
 *                 timestamp: { type: string, format: date-time }
 *                 uptimeSeconds: { type: integer, example: 3600 }
 */
app.get('/live', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
  });
});

// --- Body parsing + param pollution protection -----------------------------
// `verify` stashes the raw request bytes on req.rawBody before JSON-parsing
// happens. Only the Cashfree webhook route needs this (its HMAC signature is
// computed over the exact raw payload, not the reserialized object — even a
// harmless whitespace/key-order difference would break verification), but
// capturing it globally here is cheap and keeps app.js from having to special-case
// body-parser setup per route.
app.use(
  express.json({
    limit: env.bodyLimit,
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  })
);
app.use(hpp()); // strips duplicate query params (e.g. ?difficulty=Easy&difficulty=Hard) to the last value

// --- Rate limiting --------------------------------------------------------
app.use(apiLimiter);

// --- API documentation (Swagger / OpenAPI) ---------------------------------
// Interactive docs at /api-docs, raw spec (for codegen/import into Postman
// etc.) at /api-docs.json. Generated from the JSDoc `@openapi` blocks in
// src/routes/*.js and src/app.js — see src/config/swagger.js.
app.get('/api-docs.json', (req, res) => {
  res.json(swaggerSpec);
});

// Swagger UI renders an actual HTML page and bootstraps itself with an
// inline <script>, so the strict `default-src 'none'` CSP set globally above
// would break it. This override applies only to the swaggerUi middleware
// below (not /api-docs.json, which keeps the strict global CSP) and grants
// just what swagger-ui-express actually needs to render.
app.use(
  '/api-docs',
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:'],
      connectSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameAncestors: ["'none'"],
    },
  }),
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpec, { customSiteTitle: 'GK Quiz API Docs' })
);

// --- Routes -----------------------------------------------------------
app.use('/api/auth', authRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/audit-logs', auditLogRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin/dashboard', dashboardRoutes);
app.use('/api/admin/users', userRoutes);

// --- 404 + centralized error handling (must be last) -----------------------
app.use(notFound);
app.use(errorHandler);

module.exports = app;
