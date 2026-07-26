const env = require('../config/env');
const logger = require('../config/logger');

// 404 handler — mounted after all real routes.
function notFound(req, res, next) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

// Maps a handful of well-known, non-application error shapes (malformed
// JSON bodies, our own CORS rejection, Postgres constraint violations, JWT
// errors that slip through) to sensible HTTP statuses/messages. Anything
// application code throws with an explicit `err.status` (see the `httpError`
// helpers in the service layer) is left untouched.
function normalizeError(err) {
  if (err.status) return err;

  // express.json() body-parser failure on malformed JSON
  if (err.type === 'entity.parse.failed' || err instanceof SyntaxError) {
    err.status = 400;
    err.message = 'Malformed JSON in request body';
    return err;
  }

  // Our CORS origin check in app.js throws a plain Error with this message
  if (err.message === 'Not allowed by CORS') {
    err.status = 403;
    return err;
  }

  // express.json() payload too large
  if (err.type === 'entity.too.large') {
    err.status = 413;
    err.message = 'Request body too large';
    return err;
  }

  // node-postgres error codes (https://www.postgresql.org/docs/current/errcodes-appendix.html)
  if (err.code === '23505') {
    err.status = 409;
    err.message = 'Resource already exists';
    return err;
  }
  if (err.code === '23503') {
    err.status = 400;
    err.message = 'Invalid reference to a related resource';
    return err;
  }

  // jsonwebtoken errors, in case they ever bypass the auth middleware's own handling
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    err.status = 401;
    err.message = 'Invalid or expired token';
    return err;
  }

  return err;
}

// Express recognizes error-handling middleware by its 4-argument signature.
// Must be the last app.use() in app.js.
function errorHandler(err, req, res, next) {
  const normalized = normalizeError(err);
  const status = normalized.status || 500;

  // Always log server-side, with stack trace, regardless of environment.
  // winston.error writes to the console transport, logs/combined.log, and
  // logs/error.log (the error.log transport filters to level 'error' only).
  logger.error(`${req.method} ${req.originalUrl} -> ${normalized.message}`, {
    status,
    stack: normalized.stack,
  });

  const message =
    status === 500 && env.nodeEnv === 'production'
      ? 'Internal server error'
      : normalized.message || 'Internal server error';

  const body = { error: message };
  if (env.nodeEnv !== 'production' && normalized.stack) {
    body.stack = normalized.stack;
  }

  res.status(status).json(body);
}

module.exports = { notFound, errorHandler };
