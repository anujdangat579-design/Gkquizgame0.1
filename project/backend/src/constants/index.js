// Central place for fixed values shared across models, services, and
// sockets — avoids magic strings/numbers scattered across the codebase.

const DIFFICULTIES = ['Easy', 'Medium', 'Hard'];
const QUESTION_COUNT_OPTIONS = [10, 20, 30];

const ROLES = {
  PLAYER: 'player',
  ADMIN: 'admin',
};

const MATCH_STATUS = {
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  ABANDONED: 'abandoned',
};

const QUESTION_TIME_LIMIT_MS = 15000; // 15 seconds to answer each question
const NEXT_QUESTION_DELAY_MS = 2000; // pause after revealing an answer before the next question
const BCRYPT_SALT_ROUNDS = 12;

// Window both matched players have to explicitly accept before the match is
// torn down and both entry fees are released back (nobody gets stuck
// holding a locked payment for an opponent who never confirmed).
const MATCH_ACCEPT_TIMEOUT_MS = 20000;
const COUNTDOWN_START_SECONDS = 3; // synchronized 3...2...1 before question 1
const COUNTDOWN_TICK_MS = 1000;

// 'password' is the existing username/password flow (used by admins and any
// password-based players) — untouched by the OTP/Google additions.
const AUTH_PROVIDERS = {
  PASSWORD: 'password',
  OTP: 'otp',
  GOOGLE: 'google',
};

const PAYMENT_STATUS = {
  CREATED: 'CREATED',
  PAID: 'PAID',
  FAILED: 'FAILED',
  EXPIRED: 'EXPIRED',
};

const OTP_LENGTH = 6;
const OTP_TTL_SECONDS = 5 * 60; // OTP expires 5 minutes after being requested
const OTP_MAX_ATTEMPTS = 5; // wrong-code guesses allowed before the OTP is invalidated
const OTP_RESEND_COOLDOWN_SECONDS = 60; // minimum gap between two OTP requests for the same phone

module.exports = {
  DIFFICULTIES,
  QUESTION_COUNT_OPTIONS,
  ROLES,
  MATCH_STATUS,
  QUESTION_TIME_LIMIT_MS,
  NEXT_QUESTION_DELAY_MS,
  BCRYPT_SALT_ROUNDS,
  MATCH_ACCEPT_TIMEOUT_MS,
  COUNTDOWN_START_SECONDS,
  COUNTDOWN_TICK_MS,
  AUTH_PROVIDERS,
  PAYMENT_STATUS,
  OTP_LENGTH,
  OTP_TTL_SECONDS,
  OTP_MAX_ATTEMPTS,
  OTP_RESEND_COOLDOWN_SECONDS,
};
