const rateLimit = require('express-rate-limit');
const env = require('../config/env');

// General API limiter — applied to all routes.
const apiLimiter = rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: env.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again shortly.' },
});

// Stricter limiter for auth endpoints to slow down credential stuffing /
// brute force attempts.
const authLimiter = rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: env.rateLimit.authMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many auth attempts, please try again shortly.' },
});

// Stricter still than authLimiter: each hit here can trigger a real SMS
// send (cost + abuse potential for "SMS bombing" a phone number), on top of
// the per-phone cooldown enforced in authService.requestOtp.
const otpRequestLimiter = rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: Math.max(1, Math.min(env.rateLimit.authMax, 5)),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many OTP requests, please try again shortly.' },
});

module.exports = { apiLimiter, authLimiter, otpRequestLimiter };
