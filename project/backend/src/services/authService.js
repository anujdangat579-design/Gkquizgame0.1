const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const userModel = require('../models/userModel');
const refreshTokenModel = require('../models/refreshTokenModel');
const leaderboardModel = require('../models/leaderboardModel');
const auditService = require('./auditService');
const redis = require('../config/redis');
const smsService = require('./smsService');
const googleAuthService = require('./googleAuthService');
const { signAccessToken, signRefreshToken, verifyRefreshToken, hashToken } = require('../utils/jwt');
const { generateOtp, hashOtp } = require('../utils/otp');
const {
  BCRYPT_SALT_ROUNDS,
  OTP_TTL_SECONDS,
  OTP_MAX_ATTEMPTS,
  OTP_RESEND_COOLDOWN_SECONDS,
} = require('../constants');

function publicUser(row) {
  return {
    id: row.id,
    username: row.username,
    email: row.email,
    role: row.role,
  };
}

// Generates a random, unique-enough handle for accounts created via OTP/
// Google that never gave us a username ("player_a1b2c3d4"). Existing
// username/password registration is untouched — this is only used by the
// new OTP/Google flows.
async function generateUniqueUsername(prefix = 'player') {
  for (let i = 0; i < 5; i += 1) {
    const candidate = `${prefix}_${crypto.randomBytes(4).toString('hex')}`;
    // eslint-disable-next-line no-await-in-loop
    const taken = await userModel.existsByUsername(candidate);
    if (!taken) return candidate;
  }
  // Astronomically unlikely to be reached, but fall back to a longer
  // suffix rather than looping forever.
  return `${prefix}_${crypto.randomBytes(8).toString('hex')}`;
}

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

async function issueTokenPair(user) {
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  const decoded = jwt.decode(refreshToken);

  await refreshTokenModel.create({
    id: uuidv4(),
    userId: user.id,
    tokenHash: hashToken(refreshToken),
    expiresAt: new Date(decoded.exp * 1000),
  });

  return { accessToken, refreshToken };
}

async function register({ username, email, password }, meta = {}) {
  const normalizedEmail = email.toLowerCase();

  const exists = await userModel.existsByUsernameOrEmail(username, normalizedEmail);
  if (exists) throw httpError('Username or email already in use', 409);

  const passwordHash = await bcrypt.hash(password, BCRYPT_SALT_ROUNDS);
  const user = await userModel.create({
    id: uuidv4(),
    username,
    email: normalizedEmail,
    passwordHash,
  });
  await leaderboardModel.initForUser(user.id);

  const tokens = await issueTokenPair(user);
  await auditService.logRegistration({
    userId: user.id,
    username: user.username,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
  return { user: publicUser(user), ...tokens };
}

async function login({ username, password }, meta = {}) {
  const { ipAddress, userAgent } = meta;

  const user = await userModel.findAuthByIdentifier(username);
  if (!user) {
    await auditService.logLoginAttempt({
      identifier: username,
      status: 'failure',
      reason: 'user_not_found',
      ipAddress,
      userAgent,
    });
    throw httpError('Invalid username or password', 401);
  }
  if (user.is_blocked) {
    await auditService.logLoginAttempt({
      identifier: username,
      userId: user.id,
      username: user.username,
      status: 'failure',
      reason: 'account_blocked',
      ipAddress,
      userAgent,
    });
    throw httpError('This account has been blocked', 403);
  }

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    await auditService.logLoginAttempt({
      identifier: username,
      userId: user.id,
      username: user.username,
      status: 'failure',
      reason: 'invalid_password',
      ipAddress,
      userAgent,
    });
    throw httpError('Invalid username or password', 401);
  }

  const tokens = await issueTokenPair(user);
  await auditService.logLoginAttempt({
    identifier: username,
    userId: user.id,
    username: user.username,
    status: 'success',
    ipAddress,
    userAgent,
  });
  return { user: publicUser(user), ...tokens };
}

async function refresh({ refreshToken }) {
  if (!refreshToken) throw httpError('refreshToken is required', 400);

  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch (err) {
    throw httpError('Invalid or expired refresh token', 401);
  }

  const tokenHash = hashToken(refreshToken);
  const stored = await refreshTokenModel.findByUserAndHash(payload.sub, tokenHash);
  if (!stored || stored.revoked || new Date(stored.expires_at) < new Date()) {
    throw httpError('Refresh token is no longer valid', 401);
  }

  const user = await userModel.findAuthById(payload.sub);
  if (!user || user.is_blocked) throw httpError('Account not available', 403);

  // Rotate: revoke the old refresh token and issue a new one.
  await refreshTokenModel.revokeById(stored.id);
  return issueTokenPair(user);
}

async function logout({ refreshToken }) {
  if (refreshToken) {
    await refreshTokenModel.revokeByHash(hashToken(refreshToken));
  }
}

async function getProfile(userId) {
  const user = await userModel.findPublicById(userId);
  if (!user) throw httpError('User not found', 404);
  return user;
}

async function updateProfile(userId, { name, avatarUrl, email }) {
  const normalizedEmail = email ? email.toLowerCase() : undefined;
  const user = await userModel.updateProfile(userId, { name, avatarUrl, email: normalizedEmail });
  if (!user) throw httpError('User not found', 404);
  return user;
}

// --- Mobile OTP login -------------------------------------------------
// Redis-backed, short-lived, hashed-at-rest (same rationale as refresh
// tokens: a Redis dump alone shouldn't hand out a usable code). Entirely
// separate storage/flow from the password-based login above, so it can't
// interfere with admin authentication.

const otpCodeKey = (phone) => `otp:code:${phone}`;
const otpAttemptsKey = (phone) => `otp:attempts:${phone}`;
const otpCooldownKey = (phone) => `otp:cooldown:${phone}`;

async function requestOtp({ phone }, meta = {}) {
  const onCooldown = await redis.get(otpCooldownKey(phone));
  if (onCooldown) {
    throw httpError('Please wait before requesting another OTP', 429);
  }

  const otp = generateOtp();
  await redis.set(otpCodeKey(phone), hashOtp(otp, phone), 'EX', OTP_TTL_SECONDS);
  await redis.del(otpAttemptsKey(phone));
  await redis.set(otpCooldownKey(phone), '1', 'EX', OTP_RESEND_COOLDOWN_SECONDS);

  await smsService.sendOtpSms(phone, otp);
  await auditService.record({
    category: auditService.CATEGORY.AUTH,
    action: 'OTP_REQUESTED',
    entityType: 'user',
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
    metadata: { phone },
  });

  return { message: 'OTP sent', expiresInSeconds: OTP_TTL_SECONDS };
}

async function verifyOtp({ phone, otp }, meta = {}) {
  const { ipAddress, userAgent } = meta;
  const storedHash = await redis.get(otpCodeKey(phone));
  if (!storedHash) {
    throw httpError('OTP expired or was not requested — please request a new one', 400);
  }

  const attempts = parseInt((await redis.get(otpAttemptsKey(phone))) || '0', 10);
  if (attempts >= OTP_MAX_ATTEMPTS) {
    await redis.del(otpCodeKey(phone));
    throw httpError('Too many incorrect attempts — please request a new OTP', 429);
  }

  const candidateHash = hashOtp(otp, phone);
  const matches =
    storedHash.length === candidateHash.length &&
    crypto.timingSafeEqual(Buffer.from(storedHash), Buffer.from(candidateHash));

  if (!matches) {
    await redis.set(otpAttemptsKey(phone), String(attempts + 1), 'EX', OTP_TTL_SECONDS);
    await auditService.logLoginAttempt({
      identifier: phone,
      status: 'failure',
      reason: 'invalid_otp',
      ipAddress,
      userAgent,
    });
    throw httpError('Invalid OTP', 401);
  }

  await redis.del(otpCodeKey(phone));
  await redis.del(otpAttemptsKey(phone));

  let user = await userModel.findAuthByPhone(phone);
  let isNewUser = false;
  if (!user) {
    const username = await generateUniqueUsername('player');
    user = await userModel.createWithPhone({ id: uuidv4(), username, phone });
    isNewUser = true;
    await leaderboardModel.initForUser(user.id);
  } else if (user.is_blocked) {
    await auditService.logLoginAttempt({
      identifier: phone,
      userId: user.id,
      username: user.username,
      status: 'failure',
      reason: 'account_blocked',
      ipAddress,
      userAgent,
    });
    throw httpError('This account has been blocked', 403);
  }

  const tokens = await issueTokenPair(user);
  if (isNewUser) {
    await auditService.logRegistration({ userId: user.id, username: user.username, ipAddress, userAgent });
  }
  await auditService.logLoginAttempt({
    identifier: phone,
    userId: user.id,
    username: user.username,
    status: 'success',
    ipAddress,
    userAgent,
  });

  return { user: publicUser(user), isNewUser, ...tokens };
}

// --- Google login -------------------------------------------------------
async function googleLogin({ idToken }, meta = {}) {
  const { ipAddress, userAgent } = meta;
  const { googleId, email, name, avatarUrl } = await googleAuthService.verifyGoogleIdToken(idToken);

  let user = await userModel.findAuthByGoogleId(googleId);
  let isNewUser = false;

  if (!user && email) {
    // Link onto an existing password-registered account with the same email
    // instead of creating a duplicate user.
    const existingByEmail = await userModel.findAuthByEmail(email);
    if (existingByEmail) {
      if (existingByEmail.is_blocked) {
        await auditService.logLoginAttempt({
          identifier: email,
          userId: existingByEmail.id,
          username: existingByEmail.username,
          status: 'failure',
          reason: 'account_blocked',
          ipAddress,
          userAgent,
        });
        throw httpError('This account has been blocked', 403);
      }
      user = await userModel.linkGoogleId(existingByEmail.id, { googleId, name, avatarUrl });
    }
  }

  if (!user) {
    const username = await generateUniqueUsername('g');
    user = await userModel.createWithGoogle({ id: uuidv4(), username, email, googleId, name, avatarUrl });
    isNewUser = true;
    await leaderboardModel.initForUser(user.id);
  } else if (user.is_blocked) {
    await auditService.logLoginAttempt({
      identifier: email || googleId,
      userId: user.id,
      username: user.username,
      status: 'failure',
      reason: 'account_blocked',
      ipAddress,
      userAgent,
    });
    throw httpError('This account has been blocked', 403);
  }

  const tokens = await issueTokenPair(user);
  if (isNewUser) {
    await auditService.logRegistration({ userId: user.id, username: user.username, ipAddress, userAgent });
  }
  await auditService.logLoginAttempt({
    identifier: email || googleId,
    userId: user.id,
    username: user.username,
    status: 'success',
    ipAddress,
    userAgent,
  });

  return { user: publicUser(user), isNewUser, ...tokens };
}

module.exports = {
  register,
  login,
  refresh,
  logout,
  getProfile,
  updateProfile,
  requestOtp,
  verifyOtp,
  googleLogin,
};
