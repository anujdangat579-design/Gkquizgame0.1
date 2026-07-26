const db = require('../database/connection');

async function insert({
  id,
  category,
  action,
  status,
  actorId,
  actorUsername,
  entityType,
  entityId,
  ipAddress,
  userAgent,
  metadata,
}) {
  const result = await db.query(
    `INSERT INTO audit_logs
       (id, category, action, status, actor_id, actor_username, entity_type, entity_id, ip_address, user_agent, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING *`,
    [
      id,
      category,
      action,
      status,
      actorId || null,
      actorUsername || null,
      entityType || null,
      entityId || null,
      ipAddress || null,
      userAgent || null,
      metadata ? JSON.stringify(metadata) : null,
    ]
  );
  return result.rows[0];
}

// Builds a WHERE clause + params array from whichever filters are present,
// then runs both the page query and a matching COUNT so the caller can
// paginate. Filters are all optional and combined with AND.
async function list({ category, action, status, actorId, entityType, entityId, from, to, limit, offset }) {
  const conditions = [];
  const params = [];

  function eq(column, value) {
    params.push(value);
    conditions.push(`${column} = $${params.length}`);
  }

  if (category) eq('category', category);
  if (action) eq('action', action);
  if (status) eq('status', status);
  if (actorId) eq('actor_id', actorId);
  if (entityType) eq('entity_type', entityType);
  if (entityId) eq('entity_id', entityId);
  if (from) {
    params.push(from);
    conditions.push(`created_at >= $${params.length}`);
  }
  if (to) {
    params.push(to);
    conditions.push(`created_at <= $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countResult = await db.query(`SELECT COUNT(*)::int AS count FROM audit_logs ${where}`, params);

  const pageParams = [...params, limit, offset];
  const result = await db.query(
    `SELECT * FROM audit_logs ${where} ORDER BY created_at DESC LIMIT $${pageParams.length - 1} OFFSET $${pageParams.length}`,
    pageParams
  );

  return { rows: result.rows, total: countResult.rows[0].count };
}

module.exports = { insert, list };
