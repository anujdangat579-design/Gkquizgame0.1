const userModel = require('../models/userModel');

class ServiceError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

function buildPagination({ page, limit, total }) {
  return {
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit)),
  };
}

async function listUsers(query) {
  const { rows, total } = await userModel.findUsers(query);
  return { users: rows, pagination: buildPagination({ page: query.page, limit: query.limit, total }) };
}

// Search is list-with-required-q; kept as a separate function so the two
// routes can be validated with different schemas (q optional vs required)
// while sharing one query path.
async function searchUsers(query) {
  return listUsers(query);
}

async function getUserById(id) {
  const user = await userModel.findById(id);
  if (!user) throw new ServiceError(404, 'User not found');
  return user;
}

// Shared guardrails for every status-changing action, so an admin can't
// accidentally lock themselves out or unilaterally act on another admin
// account through this endpoint.
async function assertMutable(targetId, actorId) {
  if (targetId === actorId) {
    throw new ServiceError(400, 'You cannot change the status of your own account');
  }
  const target = await userModel.findRoleById(targetId);
  if (!target) throw new ServiceError(404, 'User not found');
  if (target.role === 'admin') {
    throw new ServiceError(403, 'Admin accounts cannot be blocked, unblocked, or suspended through this endpoint');
  }
}

async function blockUser(id, { reason, actorId }) {
  await assertMutable(id, actorId);
  const user = await userModel.updateStatus(id, {
    status: 'blocked',
    reason,
    changedBy: actorId,
    suspendedUntil: null,
  });
  await userModel.revokeActiveSessions(id);
  return user;
}

async function unblockUser(id, { reason, actorId }) {
  await assertMutable(id, actorId);
  const user = await userModel.updateStatus(id, {
    status: 'active',
    reason,
    changedBy: actorId,
    suspendedUntil: null,
  });
  return user;
}

async function suspendUser(id, { reason, days, until, actorId }) {
  await assertMutable(id, actorId);
  const suspendedUntil = until ? new Date(until) : new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  const user = await userModel.updateStatus(id, {
    status: 'suspended',
    reason,
    changedBy: actorId,
    suspendedUntil,
  });
  await userModel.revokeActiveSessions(id);
  return user;
}

module.exports = {
  ServiceError,
  listUsers,
  searchUsers,
  getUserById,
  blockUser,
  unblockUser,
  suspendUser,
};
