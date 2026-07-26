const crypto = require('crypto');
const { OTP_LENGTH } = require('../constants');

// Cryptographically random numeric code, e.g. "042917" for OTP_LENGTH = 6.
// Zero-padded so leading zeros aren't dropped.
function generateOtp() {
  const max = 10 ** OTP_LENGTH;
  const n = crypto.randomInt(0, max);
  return String(n).padStart(OTP_LENGTH, '0');
}

// Same rationale as refresh-token hashing (see utils/jwt.js): only a hash of
// the OTP is ever stored (in Redis), so a Redis dump doesn't hand out usable
// codes.
function hashOtp(otp, phone) {
  return crypto.createHash('sha256').update(`${phone}:${otp}`).digest('hex');
}

module.exports = { generateOtp, hashOtp };
