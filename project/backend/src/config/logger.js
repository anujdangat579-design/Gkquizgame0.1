const fs = require('fs');
const path = require('path');
const winston = require('winston');
const env = require('./env');

// Winston doesn't create the log directory for you — do it up front so the
// File transports below don't fail on a fresh checkout/deploy.
const logsDir = path.join(__dirname, '..', '..', 'logs');
fs.mkdirSync(logsDir, { recursive: true });

const { combine, timestamp, errors, printf, colorize, json, splat } = winston.format;

// Human-readable line format used for the console transport in development.
const consoleFormat = printf(({ level, message, timestamp: ts, stack, ...meta }) => {
  const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
  return `${ts} [${level}]: ${stack || message}${metaStr}`;
});

const logger = winston.createLogger({
  level: env.logLevel,
  levels: winston.config.npm.levels, // error(0) warn(1) info(2) http(3) verbose(4) debug(5) silly(6)
  format: combine(
    errors({ stack: true }), // capture err.stack when an Error object is logged
    timestamp(),
    splat(),
    json()
  ),
  defaultMeta: { service: 'gk-quiz-backend' },
  transports: [
    // All logs (info and above by default) — general operational history.
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      level: env.logLevel,
      maxsize: 10 * 1024 * 1024, // 10MB per file
      maxFiles: 5,
      tailable: true,
    }),
    // Errors only — makes production incident triage fast without grepping
    // through the full combined log.
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 10 * 1024 * 1024,
      maxFiles: 5,
      tailable: true,
    }),
  ],
  exitOnError: false,
});

// Console output: always on, but human-readable/colorized outside production
// so local `npm run dev` stays pleasant. In production the console still
// gets JSON (handy if Render's log viewer or a log drain is watching stdout).
logger.add(
  new winston.transports.Console({
    format:
      env.nodeEnv === 'production'
        ? combine(timestamp(), json())
        : combine(colorize(), timestamp(), errors({ stack: true }), consoleFormat),
  })
);

// A minimal stream adapter so morgan (HTTP access log formatting) can write
// through winston instead of straight to stdout — keeps all logging,
// HTTP and application-level, flowing through the same transports/files.
logger.stream = {
  write: (message) => logger.http(message.trim()),
};

module.exports = logger;
