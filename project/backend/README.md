# GK Quiz Backend

Secure Node.js + Express backend for a 1v1 General Knowledge quiz app. Matches are
decided purely by correct answers — but joining matchmaking now requires a paid,
Cashfree-verified entry fee (see "Payments (Cashfree)" below); there's still no
wallet or withdrawal system, only a one-way entry fee per match.

## Stack

- **Express** – REST API
- **PostgreSQL (Neon)** – via `pg`, plain SQL migrations (no ORM)
- **Redis** – caching, matchmaking queue, Socket.IO adapter (see "Redis integration" below)
- **Socket.IO** – real-time 1v1 matchmaking + live quiz rooms
- **JWT** – short-lived access tokens + rotating refresh tokens
- **Helmet, CORS (whitelist), express-rate-limit, HPP, compression, morgan** – security & production hardening
- **Cashfree Payment Gateway** – matchmaking entry fee (order creation + webhook)
- **Render** – deploy target (`render.yaml` included)

## Production hardening

This API ships with the following built in (see `src/app.js` / `src/server.js`):

- **Helmet** – secure HTTP headers (`crossOriginResourcePolicy: cross-origin` so the frontend can load API responses; CSP left off since this is a pure JSON API).
- **CORS whitelist** – origins come from `CORS_ORIGINS` (comma-separated) in `.env`; anything not listed is rejected with a 403. Applies to both REST and Socket.IO.
- **Compression** – gzip/deflate on responses via `compression`.
- **Rate limiting** – general limiter on all routes + a stricter limiter on `/api/auth/*` (`express-rate-limit`, tunable via `RATE_LIMIT_*` / `AUTH_RATE_LIMIT_MAX`).
- **Winston logging** – structured JSON logs to console + `logs/combined.log` + `logs/error.log`; morgan formats HTTP access lines and pipes them through the same logger.
- **HPP** – `hpp` strips duplicate query-string keys (e.g. `?difficulty=Easy&difficulty=Hard`) down to a single value, closing an HTTP Parameter Pollution vector.
- **Morgan** – HTTP access-log line formatting (`combined` in prod, `dev` locally by default; override with `LOG_FORMAT`), skips `/health`, `/ready`, `/live` to avoid noise from uptime/probe pings. Output is piped into Winston rather than straight to stdout.
- **Centralized error handler** – `src/middleware/errorHandler.js` maps known error shapes (bad JSON, CORS rejection, Postgres constraint violations, JWT errors) to proper status codes, hides internal details in production, and always logs via Winston.
- **Async error wrapper** – `src/middleware/asyncHandler.js` wraps controller handlers so rejected promises are forwarded to the error handler automatically (no manual try/catch needed).
- **Global 404 handler** – any unmatched route returns a consistent JSON 404.
- **Request validation** – `express-validator` on every write endpoint (`src/validators/`), including UUID validation on all `:id` route params.
- **`x-powered-by` disabled** – both explicitly (`app.disable`) and via Helmet.
- **Graceful shutdown** – on `SIGTERM`/`SIGINT`, stops accepting new connections, closes Socket.IO, drains in-flight HTTP requests, closes the Postgres pool, then exits; force-exits after `SHUTDOWN_TIMEOUT_MS` if something hangs. Also catches `uncaughtException`/`unhandledRejection` so the process doesn't die silently.
- **Health / readiness / liveness checks** – all unauthenticated, unrate-limited, and excluded from access logs (registered before the body parser and rate limiter):
  - `GET /health` – `{ status, timestamp, uptimeSeconds, environment, database, redis }`. Always returns 200 (even if a dependency is down) — a diagnostic snapshot, not a pass/fail check.
  - `GET /ready` – checks the database and Redis are both reachable; returns 200 if so, **503** if either is down. Point orchestrator/load-balancer health checks (Render's `healthCheckPath`, k8s readiness probes) at this one.
  - `GET /live` – confirms the process itself can respond; deliberately skips DB/Redis checks so a dependency outage doesn't get an otherwise-healthy process restarted. Use for k8s liveness probes.

## Logging

Powered by **Winston** (`src/config/logger.js`), with three transports:

| Transport         | What it captures                                  |
|--------------------|----------------------------------------------------|
| Console            | Everything, colorized/human-readable in dev, JSON in production |
| `logs/combined.log`| Everything at or above `LOG_LEVEL` (default `http` in prod, `debug` in dev — includes HTTP access lines from morgan) |
| `logs/error.log`   | `error`-level entries only (unhandled errors, DB pool errors, shutdown failures, etc.) |

Files rotate at 10MB, keeping up to 5 files each (`combined.log`, `combined1.log`, ...). The `logs/` folder is created automatically on startup if it doesn't exist, and `logs/*.log` is git-ignored — only `logs/.gitkeep` is tracked so the folder itself exists on a fresh checkout.

Levels follow the standard npm/winston order: `error` < `warn` < `info` < `http` < `verbose` < `debug` < `silly`. Setting `LOG_LEVEL` controls the *maximum* verbosity written to `combined.log`/console — e.g. `LOG_LEVEL=info` hides HTTP access lines, `LOG_LEVEL=debug` shows everything including DB query timings.

## Redis integration

Redis (`REDIS_URL`, required — same treatment as `DATABASE_URL`) backs three things:

**1. Caching** (`src/services/cacheService.js`)
`GET /api/questions` and `GET /api/quiz/leaderboard` are cached (`CACHE_QUESTIONS_TTL_SECONDS` / `CACHE_LEADERBOARD_TTL_SECONDS`, default 60s/30s). Invalidation is version-based rather than key-deletion-based: each cache key embeds a namespace version number (`cache:questions:v3:...`); creating/updating/deleting a question or finishing a match increments that version, which instantly makes all previously-cached keys for that resource unreachable (they just age out on their own TTL). No `SCAN`/pattern-delete needed. If Redis is unreachable, cache reads/writes fail silently (logged as warnings) and requests fall through to Postgres — a Redis outage degrades latency, not availability.

**2. Matchmaking queue** (`src/services/matchmakingService.js`)
Replaces the old in-memory `Map` queue. Each `category:difficulty:questionCount` bucket is a Redis list; joining/pairing is done via a single Lua script (`EVAL`) so "already queued?", "push", and "pair the first two off if ≥2 are waiting" happen atomically — safe even if this server runs as multiple instances behind a load balancer, all sharing the same Redis. Per-user queue markers carry a 5-minute TTL as a safety net in case a process dies mid-queue.

**3. Socket.IO adapter** (`src/server.js`, `@socket.io/redis-adapter`)
`io.to(room).emit(...)` and friends are relayed through Redis pub/sub, so events reach sockets connected to *any* instance, not just the one that emitted them. This is what makes it safe to run more than one instance of this server.

> **Known limitation:** live match state in `quizRoomService.js` (`activeMatches`, including question timers) is still held in-process, not in Redis. With the adapter in place, broadcasts to a match's room work correctly across instances, but the match's own timers/logic only run on the instance that created it — moving that to Redis (e.g. with a distributed timer/job mechanism) is a reasonable next step if you scale past a single instance, but is out of scope here.

Local dev: `docker run -d -p 6379:6379 redis:7-alpine` and set `REDIS_URL=redis://localhost:6379` in `.env`. In production, provision a managed Redis (Render Redis, Upstash, etc.) and set `REDIS_URL` there — use `rediss://` if the provider requires TLS.

## Setup

```bash
npm install
cp .env.example .env
# fill in DATABASE_URL (from Neon), REDIS_URL (see "Redis integration" above), JWT secrets, CORS_ORIGINS
npm run migrate   # creates tables in your Neon database
npm run dev        # local dev with nodemon
```

## Deploying to Render

1. Push this folder to a Git repo.
2. In Render, "New +" → "Blueprint" → point at the repo (uses `render.yaml`).
3. Set `DATABASE_URL` (Neon connection string, `sslmode=require`), `REDIS_URL`
   (from a Render Redis instance, Upstash, etc.), and `CORS_ORIGINS`
   (your frontend's URL) in the Render dashboard — these are marked `sync: false`
   so they aren't committed to git.
4. After first deploy, run `npm run migrate` once (Render Shell, or a one-off job)
   to create the schema.

## REST API

> **Interactive docs:** run the server and open `http://localhost:<PORT>/api-docs` for a
> Swagger UI you can browse and try requests against directly (raw OpenAPI 3.0 JSON at
> `/api-docs.json`). The spec is generated from JSDoc `@openapi` blocks in `src/routes/*.js`
> (config in `src/config/swagger.js`) — add a block there whenever a route changes so the
> docs stay in sync with the code.

All authenticated routes expect `Authorization: Bearer <accessToken>`.

| Method | Path                      | Auth       | Description                          |
|--------|---------------------------|------------|--------------------------------------|
| POST   | `/api/auth/register`      | none       | Create account                       |
| POST   | `/api/auth/login`         | none       | Login, returns access+refresh tokens |
| POST   | `/api/auth/refresh`       | none       | Rotate refresh token                 |
| POST   | `/api/auth/logout`        | none       | Revoke a refresh token               |
| GET    | `/api/auth/me`            | user       | Current user profile                 |
| PATCH  | `/api/auth/profile`       | user       | Update name / avatarUrl / email      |
| POST   | `/api/auth/otp/request`   | none       | Send a 6-digit login OTP to a phone number |
| POST   | `/api/auth/otp/verify`    | none       | Verify OTP; logs in, creating the account on first use |
| POST   | `/api/auth/google`        | none       | Log in (or register) with a Google ID token |
| GET    | `/api/questions`          | user       | List questions (filter by ?category, ?difficulty) |
| POST   | `/api/questions`          | admin      | Create a question                    |
| POST   | `/api/questions/bulk`     | admin      | Bulk-import questions                |
| PATCH  | `/api/questions/:id`      | admin      | Edit a question                      |
| DELETE | `/api/questions/:id`      | admin      | Delete a question                    |
| GET    | `/api/quiz/leaderboard`   | user       | Global leaderboard                   |
| GET    | `/api/quiz/matches/mine`  | user       | Your match history                   |
| GET    | `/api/quiz/matches/:id`   | user       | Match detail + answer log            |
| POST   | `/api/payments/orders`               | user       | Create a Cashfree order for the entry fee |
| GET    | `/api/payments/orders/:orderId/verify` | user     | Re-check an order's status directly with Cashfree |
| POST   | `/api/payments/webhook`              | signature  | Cashfree payment webhook (HMAC-verified, not JWT) |

Making a user an admin is a manual step (`UPDATE users SET role = 'admin' WHERE id = ...`) —
there's intentionally no self-service "become admin" endpoint.

**Auth methods:** `/api/auth/register` + `/api/auth/login` (username/password) is the original
flow and is what admin accounts use — it's unchanged. `/api/auth/otp/*` and `/api/auth/google`
are additive player-login methods that issue the same JWT access/refresh token pair via the same
`/api/auth/refresh` and `/api/auth/logout` endpoints; a phone- or Google-created account still
gets `role = 'player'` by default. OTP delivery defaults to logging the code to the console
(`SMS_PROVIDER=console`) so it works locally with no SMS credentials — see `.env.example` for
switching to Twilio/MSG91 in production. Google login requires `GOOGLE_CLIENT_ID` to be set.

## Payments (Cashfree)

Joining matchmaking (`matchmaking:join` over Socket.IO) is gated on holding a
**verified, unspent** Cashfree order. The flow:

1. Client calls `POST /api/payments/orders` (optionally with `{ category, difficulty,
   questionCount }` — stored for reference only; the charged amount always comes from
   `MATCH_ENTRY_FEE_AMOUNT`/`MATCH_ENTRY_FEE_CURRENCY` server-side, never from the
   client). Response includes `paymentSessionId` for Cashfree's Drop-in/mobile SDK or
   hosted checkout.
2. Client completes payment in Cashfree's UI.
3. Order gets marked `PAID` in our DB one of two ways:
   - **Webhook (source of truth):** Cashfree POSTs to `/api/payments/webhook`,
     verified via the `x-webhook-signature`/`x-webhook-timestamp` headers (HMAC-SHA256
     over the raw body, using `CASHFREE_WEBHOOK_SECRET`). Configure this URL in the
     Cashfree dashboard.
   - **Client fast-path:** right after checkout closes, the client can call
     `GET /api/payments/orders/:orderId/verify`, which re-checks status directly with
     Cashfree (in case the webhook hasn't landed yet).
4. Client emits `matchmaking:join`. The server atomically claims the oldest `PAID`,
   unspent order for that user (`FOR UPDATE SKIP LOCKED`, so a double-click can't
   claim the same order twice) before adding them to the queue. No spendable order →
   the ack contains `{ error: ..., code: 'PAYMENT_REQUIRED' }` and nothing is queued.
5. The claimed order is only *permanently* spent once it actually produces a match —
   `payments.match_id` gets set at that point. If the user cancels
   (`matchmaking:cancel`), disconnects while still waiting, or the match fails to
   form (e.g. not enough questions in the bank), the claim is released and the same
   paid order can be used for a later `matchmaking:join`.

Required env vars: `CASHFREE_APP_ID`, `CASHFREE_SECRET_KEY`, `CASHFREE_ENV`
(`SANDBOX`/`PRODUCTION`), `CASHFREE_WEBHOOK_SECRET`, `MATCH_ENTRY_FEE_AMOUNT`,
`MATCH_ENTRY_FEE_CURRENCY` — see `.env.example`. Get sandbox credentials from
[merchant.cashfree.com](https://merchant.cashfree.com/merchants/pg/credentials).

**Minimal client flow** (Cashfree's `cashfree-js` Drop-in, web/React):

```js
import { load } from '@cashfreepayments/cashfree-js';

const cashfree = await load({ mode: 'sandbox' }); // 'production' when CASHFREE_ENV=PRODUCTION

// 1. Ask our backend to open an order
const { order } = await api.post('/api/payments/orders', { difficulty: 'Easy', questionCount: 10 });

// 2. Let Cashfree collect payment
await cashfree.checkout({ paymentSessionId: order.paymentSessionId, redirectTarget: '_modal' });

// 3. Fast-path confirm (webhook is still the real source of truth server-side)
const { status } = await api.get(`/api/payments/orders/${order.cfOrderId}/verify`);
if (status === 'PAID') {
  socket.emit('matchmaking:join', { difficulty: 'Easy', questionCount: 10 }, (ack) => {
    if (ack.code === 'PAYMENT_REQUIRED') {
      // webhook/verify hasn't landed yet server-side — retry verify, then join again
    }
  });
}
```

## Testing

`npm install` then `npm test` (Jest + Supertest, runs `--runInBand`). Covers `GET /health`,
`GET /ready`, `GET /live`, all `/api/auth/*` routes, `/api/quiz/*` routes, `/api/questions/*`
routes, `/api/audit-logs`, and `/api/payments/*` (order creation, verify-status, and webhook
signature handling — see `tests/payments.test.js`).

Tests never touch a real Postgres or Redis:

- `src/config/redis.js` is replaced in every test file by a manual mock
  (`src/config/__mocks__/redis.js` — a small in-memory stand-in), since the real
  module opens an eager Redis connection the moment it's `require`d.
- `src/database/connection.js` is replaced by a manual mock (`src/database/__mocks__/connection.js`)
  in test files that exercise `/health` or `/ready` directly, so `db.query('SELECT 1')` can be
  driven to resolve or reject on demand instead of attempting a real connection.
- Whichever DB-backed models a given route actually calls (`userModel`,
  `refreshTokenModel`, `leaderboardModel`, `matchModel`, `matchAnswerModel`, `questionModel`,
  `auditLogModel`) are mocked per test file with `jest.mock(...)`, with lightweight in-memory
  implementations wired up via `mockImplementation` where a stateful flow (e.g. register → login →
  refresh → logout) needs to behave consistently across requests.
- `src/services/cacheService.js` is mocked in the quiz/question tests only, so caching itself
  doesn't make assertions order-dependent across tests in the same file.

Required env vars (JWT secrets, fake `DATABASE_URL`/`REDIS_URL`, generous rate limits so
a test file's handful of requests never trips the limiter) are set in
`tests/setupEnvVars.js`, which Jest loads (via `setupFiles` in `jest.config.js`) before
`src/config/env.js` is ever required.

Test files: `tests/health.test.js`, `tests/auth.test.js`, `tests/quiz.test.js`,
`tests/questions.test.js`, `tests/auditLogs.test.js`, `tests/securityHeaders.test.js`.

## Socket.IO events

Connect with `io(URL, { auth: { token: accessToken } })`.

**Client → server**
- `matchmaking:join({ category, difficulty, questionCount })` — joins the queue; once
  paired with an opponent (same category + difficulty + questionCount), both sockets
  receive `matchmaking:matched`. **Requires a verified, unspent Cashfree order for
  this user** (see "Payments (Cashfree)" above) — without one, the ack is
  `{ error, code: 'PAYMENT_REQUIRED' }` and the user is not queued.
- `match:accept({ pendingId })` — accepts a pending match. The quiz room (and a real
  `matchId`) is only created once **both** players have accepted; until then, neither
  paid entry is spent. Unaccepted matches expire after 20s (`matchmaking:acceptTimeout`),
  releasing both entries back for reuse.
- `matchmaking:cancel()` — leaves the queue, or backs out of a not-yet-accepted pending
  match, releasing any claimed paid entry back for reuse.
- `match:submitAnswer({ matchId, questionIndex, chosenIndex })` — submits an answer to
  the current question. `questionIndex` must match the question the server currently
  has open — a stale/mismatched index (e.g. a late answer arriving just after the timer
  closed that question) is rejected with `{ error, code: 'QUESTION_CLOSED' }` rather
  than being scored against whatever question happens to be current by then.

**Server → client**
- `matchmaking:matched({ pendingId, opponents, category, difficulty, questionCount, acceptTimeoutMs })`
  — paired with an opponent; call `match:accept` to proceed.
- `match:opponentAccepted` — the opponent has accepted; still waiting on you.
- `matchmaking:acceptTimeout` / `matchmaking:opponentLeft` — the pending match fell
  through (timeout, cancel, or disconnect) before both sides accepted; your entry has
  been released and you're free to requeue.
- `match:roomCreated({ matchId, opponents, category, difficulty, questionCount, questions })`
  — the quiz room now exists: both verified payments are locked to `matchId`, and both
  players receive the identical (answer-shuffled, answer-key-withheld) question set.
  Sent once, before the countdown.
- `match:countdown({ count, matchId })` — synchronized 3...2...1 tick, once per second.
- `match:countdownComplete({ matchId })` — countdown finished; question 1's server-side
  timer starts immediately after.
- `match:question` — the next question (answer key withheld), plus `serverTime`,
  `timeLimitMs`, and `endsAt` — clients should render their countdown against `endsAt`
  (the server's clock), not a self-started local timer, since the server enforces
  `endsAt` regardless of what the client displays.
- `match:answerReceived` — an opponent answered (no content revealed).
- `match:questionResult` — reveals the correct answer once the question closes.
- `match:finished` — final scores and winner (or tie) once all questions are done.
- `match:opponentLeft` — sent if the opponent disconnects mid-match (also reused, before
  a match exists, if the opponent disconnects/cancels during the accept handshake).

Each question has a 15-second time limit; once both players answer (or time runs
out) the game reveals the answer and moves to the next question. The winner is
whoever answered more questions correctly — a tie is a tie, with no forced
"revenue-optimal" outcome anywhere in the logic.

## Security notes

- Passwords hashed with bcrypt (cost factor 12).
- Refresh tokens stored only as SHA-256 hashes, rotated on every use.
- Question `correct_index` never leaves the server before the round closes.
- All mutating question-bank endpoints require `role = 'admin'`.
- Rate limiting: generous global limit, stricter limit on `/api/auth/*`.
- `trust proxy` enabled for correct client IPs behind Render's proxy.
