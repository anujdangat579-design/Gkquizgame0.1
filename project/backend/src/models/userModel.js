const db = require('../database/connection');

const PUBLIC_COLUMNS = `
  id, username, email, phone, name, avatar_url, role, auth_provider,
  status, suspended_until, status_reason, status_changed_by, status_changed_at,
  created_at
`;

const SORT_COLUMNS = {
  created_at: 'created_at',
  username: 'username',
  status: 'status',
};

// Shared by both "list" and "search": search is just a list call with q
// required. Builds a parameterized WHERE clause so callers can combine any
// mix of free-text search, role, and status filters.
function buildWhereClause({ q, role, status }, params) {
  const conditions = [];

  if (q) {
    params.push(`%${q}%`);
    const idx = params.length;
    conditions.push(`(username ILIKE $${idx} OR email ILIKE $${idx} OR phone ILIKE $${idx} OR name ILIKE $${idx})`);
  }
  if (role) {
    params.push(role);
    conditions.push(`role = $${params.length}`);
  }
  if (status) {
    params.push(status);
    conditions.push(`status = $${params.length}`);
  }

  return conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
}

/**
 * Paginated user list with optional free-text search (q), role, and status
 * filters. Returns { rows, total } so the service layer can build
 * pagination metadata.
 */
async function findUsers({ q, role, status, page, limit, sortBy, sortOrder }) {
  const params = [];
  const whereClause = buildWhereClause({ q, role, status }, params);
  const sortCol = SORT_COLUMNS[sortBy] || 'created_at';
  const sortDir = sortOrder === 'asc' ? 'ASC' : 'DESC';

  const countResult = await db.query(`SELECT COUNT(*) FROM users ${whereClause}`, params);

  const offset = (page - 1) * limit;
  const dataParams = [...params, limit, offset];
  const dataResult = await db.query(
    `SELECT ${PUBLIC_COLUMNS}
     FROM users
     ${whereClause}
     ORDER BY ${sortCol} ${sortDir}, id ${sortDir}
     LIMIT $${dataParams.length - 1} OFFSET $${dataParams.length}`,
    dataParams
  );

  return {
    rows: dataResult.rows,
    total: parseInt(countResult.rows[0].count, 10),
  };
}

async function findById(id) {
  const result = await db.query(`SELECT ${PUBLIC_COLUMNS} FROM users WHERE id = $1`, [id]);
  return result.rows[0] || null;
}

async function findRoleById(id) {
  const result = await db.query('SELECT id, role FROM users WHERE id = $1', [id]);
  return result.rows[0] || null;
}

// Revokes every currently-valid refresh token for a user. Called on block
// and suspend so the status change takes effect immediately for anyone
// already logged in, rather than waiting for their access token to expire.
async function revokeActiveSessions(id) {
  await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1 AND revoked = FALSE', [id]);
}

/**
 * Sets a user's status. suspendedUntil should be a Date for 'suspended'
 * and null for 'active'/'blocked' (enforced again at the DB level by the
 * chk_suspended_until_only_when_suspended constraint).
 */
async function updateStatus(id, { status, reason, changedBy, suspendedUntil }) {
  const result = await db.query(
    `UPDATE users
     SET status = $1,
         status_reason = $2,
         status_changed_by = $3,
         status_changed_at = now(),
         suspended_until = $4
     WHERE id = $5
     RETURNING ${PUBLIC_COLUMNS}`,
    [status, reason || null, changedBy, suspendedUntil, id]
  );
  return result.rows[0] || null;
}

module.exports = {
  findUsers,
  findById,
  findRoleById,
  revokeActiveSessions,
  updateStatus,
};
