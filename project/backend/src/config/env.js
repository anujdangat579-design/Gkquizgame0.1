require('dotenv').config();

function required(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const env = {
  port: parseInt(process.env.PORT || '4000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigins: (process.env.CORS_ORIGINS || 'http://localhost:5173')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  databaseUrl: required('DATABASE_URL'),
  // Optional. Caching, OTP storage, matchmaking, and the Socket.IO adapter
  // all fall back to in-memory implementations (see config/redis.js) when
  // this isn't set — the server starts and every API works normally on a
  // single instance either way. Set it to enable real Redis.
  redisUrl: process.env.REDIS_URL || '',
  redisEnabled: Boolean(process.env.REDIS_URL),
  cache: {
    questionsTtlSeconds: parseInt(process.env.CACHE_QUESTIONS_TTL_SECONDS || '60', 10),
    leaderboardTtlSeconds: parseInt(process.env.CACHE_LEADERBOARD_TTL_SECONDS || '30', 10),
  },
  jwt: {
    accessSecret: required('JWT_ACCESS_SECRET'),
    refreshSecret: required('JWT_REFRESH_SECRET'),
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '100', 10),
    authMax: parseInt(process.env.AUTH_RATE_LIMIT_MAX || '10', 10),
  },
  // --- Mobile OTP login ---
  // No SMS provider is required to run the app locally: with SMS_PROVIDER
  // unset (or 'console'), otp/smsService.js just logs the code instead of
  // sending it, so OTP login is fully testable without any credentials.
  sms: {
    provider: process.env.SMS_PROVIDER || 'console', // 'console' | 'twilio' | 'msg91'
    twilio: {
      accountSid: process.env.TWILIO_ACCOUNT_SID || '',
      authToken: process.env.TWILIO_AUTH_TOKEN || '',
      fromNumber: process.env.TWILIO_FROM_NUMBER || '',
    },
    msg91: {
      authKey: process.env.MSG91_AUTH_KEY || '',
      templateId: process.env.MSG91_TEMPLATE_ID || '',
      senderId: process.env.MSG91_SENDER_ID || '',
    },
  },

  // --- Google login ---
  // Only required if/when a client actually calls POST /api/auth/google;
  // left optional here (not `required()`) so the app can still boot without
  // it — googleAuthService throws a clear 500 if it's used unconfigured.
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID || '',
  },

  // --- Cashfree payment gateway ---
  // Not wrapped in required() so the app can still boot (e.g. for running
  // unrelated tests) without these set; cashfreeService throws a clear 500
  // if an order/webhook call is actually attempted while unconfigured.
  cashfree: {
    appId: process.env.CASHFREE_APP_ID || '',
    secretKey: process.env.CASHFREE_SECRET_KEY || '',
    // 'SANDBOX' | 'PRODUCTION'
    env: process.env.CASHFREE_ENV || 'SANDBOX',
    apiVersion: process.env.CASHFREE_API_VERSION || '2023-08-01',
    // Falls back to the client secret if a dedicated webhook secret isn't
    // set — Cashfree lets you use either, but a separate secret is safer.
    webhookSecret: process.env.CASHFREE_WEBHOOK_SECRET || process.env.CASHFREE_SECRET_KEY || '',
    baseUrl:
      (process.env.CASHFREE_ENV || 'SANDBOX') === 'PRODUCTION'
        ? 'https://api.cashfree.com/pg'
        : 'https://sandbox.cashfree.com/pg',
    // Where Cashfree's hosted checkout redirects the browser after payment
    // (order_id is substituted in). Only needed for the hosted-checkout
    // flow; the Drop-in/SDK flow on mobile doesn't require it.
    returnUrl: process.env.CASHFREE_RETURN_URL || '',
    // Server-to-server webhook URL, configured in the Cashfree dashboard,
    // not sent by us — kept here only for reference/logging.
    notifyUrl: process.env.CASHFREE_NOTIFY_URL || '',
  },

  // Flat entry fee charged per matchmaking queue join.
  matchEntryFee: {
    amount: parseFloat(process.env.MATCH_ENTRY_FEE_AMOUNT || '10'),
    currency: process.env.MATCH_ENTRY_FEE_CURRENCY || 'INR',
  },

  bodyLimit: process.env.BODY_LIMIT || '1mb',
  logFormat: process.env.LOG_FORMAT || (process.env.NODE_ENV === 'production' ? 'combined' : 'dev'),
  logLevel: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'http' : 'debug'),
  shutdownTimeoutMs: parseInt(process.env.SHUTDOWN_TIMEOUT_MS || '10000', 10),
};

module.exports = env;
