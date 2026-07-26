const db = require('../database/connection');

async function create({ id, userId, cfOrderId, orderAmount, currency, matchCriteria }) {
  const result = await db.query(
    `INSERT INTO payments (id, user_id, cf_order_id, order_amount, currency, match_criteria, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'CREATED')
     RETURNING id, user_id, cf_order_id, order_amount, currency, status, match_criteria, created_at`,
    [id, userId, cfOrderId, orderAmount, currency, matchCriteria ? JSON.stringify(matchCriteria) : null]
  );
  return result.rows[0];
}

async function findByOrderId(cfOrderId) {
  const result = await db.query('SELECT * FROM payments WHERE cf_order_id = $1', [cfOrderId]);
  return result.rows[0] || null;
}

async function findByIdForUser(id, userId) {
  const result = await db.query('SELECT * FROM payments WHERE id = $1 AND user_id = $2', [id, userId]);
  return result.rows[0] || null;
}

// Idempotent: only transitions CREATED -> PAID. A webhook retry or a race
// with the client-side verify-status call just no-ops on the second call
// (returns null) instead of double-processing.
async function markPaidByOrderId(cfOrderId, { cfPaymentId } = {}) {
  const result = await db.query(
    `UPDATE payments
     SET status = 'PAID', cf_payment_id = COALESCE($2, cf_payment_id), paid_at = now(), updated_at = now()
     WHERE cf_order_id = $1 AND status = 'CREATED'
     RETURNING *`,
    [cfOrderId, cfPaymentId || null]
  );
  return result.rows[0] || null;
}

async function markFailedByOrderId(cfOrderId) {
  const result = await db.query(
    `UPDATE payments
     SET status = 'FAILED', updated_at = now()
     WHERE cf_order_id = $1 AND status = 'CREATED'
     RETURNING *`,
    [cfOrderId]
  );
  return result.rows[0] || null;
}

// Atomically claims the oldest paid-but-unspent order for this user and
// marks it consumed, so two concurrent matchmaking:join calls (e.g. a
// double-click, or a reconnect racing the original request) can never both
// walk away thinking they've claimed the same order. FOR UPDATE SKIP LOCKED
// means a second concurrent caller just sees no spendable row instead of
// blocking or double-claiming.
async function consumeOldestPaidForUser(userId) {
  const result = await db.query(
    `UPDATE payments
     SET consumed = TRUE, consumed_at = now(), updated_at = now()
     WHERE id = (
       SELECT id FROM payments
       WHERE user_id = $1 AND status = 'PAID' AND consumed = FALSE
       ORDER BY created_at ASC
       FOR UPDATE SKIP LOCKED
       LIMIT 1
     )
     RETURNING id, cf_order_id, order_amount, currency, match_criteria`,
    [userId]
  );
  return result.rows[0] || null;
}

// Reverses consumeOldestPaidForUser for an entry that never turned into a
// match (queue cancelled, socket disconnected while still waiting, or
// insufficient-questions failure). Guarded by match_id IS NULL so a payment
// that already produced a match can never be un-spent.
async function restoreConsumed(paymentId) {
  const result = await db.query(
    `UPDATE payments
     SET consumed = FALSE, consumed_at = NULL, updated_at = now()
     WHERE id = $1 AND match_id IS NULL
     RETURNING id`,
    [paymentId]
  );
  return result.rows[0] || null;
}

// Permanently ties a consumed payment to the match it funded — from this
// point on restoreConsumed() can no longer touch it.
async function markSpentForMatch(paymentId, matchId) {
  const result = await db.query(
    `UPDATE payments SET match_id = $2, updated_at = now() WHERE id = $1 RETURNING id`,
    [paymentId, matchId]
  );
  return result.rows[0] || null;
}

module.exports = {
  create,
  findByOrderId,
  findByIdForUser,
  markPaidByOrderId,
  markFailedByOrderId,
  consumeOldestPaidForUser,
  restoreConsumed,
  markSpentForMatch,
};
