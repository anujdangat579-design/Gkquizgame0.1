const { OAuth2Client } = require('google-auth-library');
const env = require('../config/env');

let client = null;
function getClient() {
  if (!env.google.clientId) {
    const err = new Error('Google login is not configured on this server');
    err.status = 500;
    throw err;
  }
  if (!client) client = new OAuth2Client(env.google.clientId);
  return client;
}

// Verifies a Google Sign-In ID token (sent by the mobile/web client after
// the user completes Google's own consent flow) and returns the pieces of
// the payload we care about. Throws (caught by asyncHandler -> errorHandler)
// on any invalid/expired/tampered token.
async function verifyGoogleIdToken(idToken) {
  const oauthClient = getClient();

  let ticket;
  try {
    ticket = await oauthClient.verifyIdToken({ idToken, audience: env.google.clientId });
  } catch (err) {
    const httpErr = new Error('Invalid Google token');
    httpErr.status = 401;
    throw httpErr;
  }

  const payload = ticket.getPayload();
  if (!payload) {
    const httpErr = new Error('Invalid Google token');
    httpErr.status = 401;
    throw httpErr;
  }

  return {
    googleId: payload.sub,
    email: payload.email ? payload.email.toLowerCase() : null,
    emailVerified: !!payload.email_verified,
    name: payload.name || null,
    avatarUrl: payload.picture || null,
  };
}

module.exports = { verifyGoogleIdToken };
