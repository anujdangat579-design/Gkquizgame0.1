const { v4: uuidv4 } = require('uuid');
const auditLogModel = require('../models/auditLogModel');
const logger = require('../config/logger');

const CATEGORY = { AUTH: 'auth', ADMIN: 'admin', PAYMENT: 'payment', SCORE: 'score' };
const STATUS = { SUCCESS: 'success', FAILURE: 'failure' };

// Core writer that everything below funnels through. Audit logging must
// never take down the request it's attached to — a DB hiccup here shouldn't
// turn a successful login or question edit into a 500. Failures are
// swallowed and reported to the regular application logger instead.
async function record({
  category,
  action,
  status = STATUS.SUCCESS,
  actorId = null,
  actorUsername = null,
  entityType = null,
  entityId = null,
  ipAddress = null,
  userAgent = null,
  metadata = null,
}) {
  try {
    return await auditLogModel.insert({
      id: uuidv4(),
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
    });
  } catch (err) {
    logger.error(`Failed to write audit log for action ${action}`, { stack: err.stack });
    return null;
  }
}

// --- Login / auth attempts --------------------------------------------
// Covers both outcomes: call with status 'failure' and a `reason` (e.g.
// 'user_not_found', 'invalid_password', 'account_blocked') on rejected
// attempts, and status 'success' once tokens are actually issued.
async function logLoginAttempt({ identifier, userId, username, status, reason, ipAddress, userAgent }) {
  return record({
    category: CATEGORY.AUTH,
    action: status === STATUS.SUCCESS ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE',
    status,
    actorId: userId || null,
    actorUsername: username || identifier || null,
    entityType: 'user',
    entityId: userId || null,
    ipAddress,
    userAgent,
    metadata: reason ? { reason } : null,
  });
}

// Same shape, for new account creation — kept separate from login so the
// two are easy to tell apart when filtering by action.
async function logRegistration({ userId, username, ipAddress, userAgent }) {
  return record({
    category: CATEGORY.AUTH,
    action: 'USER_REGISTERED',
    status: STATUS.SUCCESS,
    actorId: userId,
    actorUsername: username,
    entityType: 'user',
    entityId: userId,
    ipAddress,
    userAgent,
  });
}

// --- Admin actions ---------------------------------------------------------
// For question bank CRUD, user moderation (block/unblock), competition
// management, etc. `action` should be a short SCREAMING_SNAKE_CASE verb,
// e.g. 'QUESTION_CREATED', 'QUESTION_DELETED', 'USER_BLOCKED'.
async function logAdminAction({
  actorId,
  actorUsername,
  action,
  status = STATUS.SUCCESS,
  entityType,
  entityId,
  metadata,
  ipAddress,
  userAgent,
}) {
  return record({
    category: CATEGORY.ADMIN,
    action,
    status,
    actorId,
    actorUsername,
    entityType,
    entityId,
    ipAddress,
    userAgent,
    metadata,
  });
}

// --- Payments ---------------------------------------------------------
// Backs the Cashfree entry-fee flow in services/paymentService.js — order
// creation, webhook confirmation, and verify-status confirmation all log
// here with entityId set to our own payments.id row.
async function logPayment({
  actorId,
  actorUsername,
  action,
  status = STATUS.SUCCESS,
  entityId,
  metadata,
  ipAddress,
  userAgent,
}) {
  return record({
    category: CATEGORY.PAYMENT,
    action,
    status,
    actorId,
    actorUsername,
    entityType: 'payment',
    entityId,
    ipAddress,
    userAgent,
    metadata,
  });
}

// --- Score changes ------------------------------------------------------
// Fired whenever a match outcome affects a player's recorded score/stats —
// match completion (leaderboard updated) or abandonment. `actorId` is left
// null for these since they're system-driven, not a specific user's action.
async function logScoreChange({ actorId = null, action, entityId, metadata }) {
  return record({
    category: CATEGORY.SCORE,
    action,
    status: STATUS.SUCCESS,
    actorId,
    entityType: 'match',
    entityId,
    metadata,
  });
}

// --- Querying (backs the admin-facing GET /api/audit-logs endpoint) -------
async function list({ category, action, status, actorId, entityType, entityId, from, to, page = 1, pageSize = 50 }) {
  const limit = Math.min(parseInt(pageSize, 10) || 50, 200);
  const currentPage = Math.max(parseInt(page, 10) || 1, 1);
  const offset = (currentPage - 1) * limit;

  const { rows, total } = await auditLogModel.list({
    category,
    action,
    status,
    actorId,
    entityType,
    entityId,
    from,
    to,
    limit,
    offset,
  });

  return { logs: rows, total, page: currentPage, pageSize: limit };
}

module.exports = {
  CATEGORY,
  STATUS,
  record,
  logLoginAttempt,
  logRegistration,
  logAdminAction,
  logPayment,
  logScoreChange,
  list,
};
