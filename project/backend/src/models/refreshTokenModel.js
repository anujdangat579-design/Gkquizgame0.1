const db = require('../database/connection');

async function create({ id, userId, tokenHash, expiresAt }) {
  await db.query(
    `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at) VALUES ($1, $2, $3, $4)`,
    [id, userId, tokenHash, expiresAt]
  );
}

async function findByUserAndHash(userId, tokenHash) {
  const result = await db.query(
    `SELECT id, revoked, expires_at FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2`,
    [userId, tokenHash]
  );
  return result.rows[0] || null;
}

async function revokeById(id) {
  await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [id]);
}

async function revokeByHash(tokenHash) {
  await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE token_hash = $1', [tokenHash]);
}

module.exports = { create, findByUserAndHash, revokeById, revokeByHash };
