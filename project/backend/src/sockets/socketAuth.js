const { verifyAccessToken } = require('../utils/jwt');

// Requires the client to connect with `auth: { token: '<accessToken>' }`.
function socketAuth(socket, next) {
  const token = socket.handshake.auth?.token;
  if (!token) {
    return next(new Error('Authentication required'));
  }
  try {
    const payload = verifyAccessToken(token);
    socket.user = { id: payload.sub, username: payload.username, role: payload.role };
    next();
  } catch (err) {
    next(new Error('Invalid or expired token'));
  }
}

module.exports = socketAuth;
