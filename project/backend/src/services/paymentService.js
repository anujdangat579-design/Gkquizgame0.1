const { v4: uuidv4 } = require('uuid');
const paymentModel = require('../models/paymentModel');
const cashfreeService = require('./cashfreeService');
const auditService = require('./auditService');
const env = require('../config/env');
const logger = require('../config/logger');

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

// Creates a Cashfree order for the flat matchmaking entry fee and a
// corresponding CREATED row in our own `payments` table. The client uses
// the returned paymentSessionId to open Cashfree's checkout (Drop-in SDK or
// hosted page); nothing is considered paid until the webhook (or a
// verify-status call) flips the row to PAID.
async function createEntryFeeOrder(user, { category, difficulty, questionCount } = {}) {
  const cfOrderId = `order_${uuidv4()}`;
  const { amount, currency } = env.matchEntryFee;

  const { paymentSessionId, orderStatus } = await cashfreeService.createOrder({
    cfOrderId,
    amount,
    currency,
    customer: { id: user.id, username: user.username, email: user.email, phone: user.phone },
    returnUrl: env.cashfree.returnUrl,
  });

  const payment = await paymentModel.create({
    id: uuidv4(),
    userId: user.id,
    cfOrderId,
    orderAmount: amount,
    currency,
    matchCriteria: { category: category ?? null, difficulty, questionCount },
  });

  await auditService.logPayment({
    actorId: user.id,
    actorUsername: user.username,
    action: 'PAYMENT_ORDER_CREATED',
    entityId: payment.id,
    metadata: { cfOrderId, amount, currency },
  });

  return {
    paymentId: payment.id,
    cfOrderId,
    paymentSessionId,
    orderStatus,
    amount,
    currency,
  };
}

// Called from the client right after Cashfree's checkout returns/closes, as
// a fast-path complement to the webhook (which is the source of truth but
// can lag by a few seconds). Re-checks order status directly with Cashfree
// before trusting anything the client says.
async function verifyOrder(orderId, userId) {
  const payment = await paymentModel.findByOrderId(orderId);
  if (!payment || payment.user_id !== userId) {
    throw httpError('Payment order not found', 404);
  }

  if (payment.status === 'PAID') {
    return { status: 'PAID', paymentId: payment.id };
  }

  const remote = await cashfreeService.fetchOrder(orderId);

  if (remote.orderStatus === 'PAID') {
    const updated = await paymentModel.markPaidByOrderId(orderId, {});
    if (updated) {
      await auditService.logPayment({
        actorId: userId,
        action: 'PAYMENT_VERIFIED',
        entityId: updated.id,
        metadata: { cfOrderId: orderId, source: 'verify_status' },
      });
    }
    return { status: 'PAID', paymentId: payment.id };
  }

  if (['EXPIRED', 'TERMINATED'].includes(remote.orderStatus)) {
    await paymentModel.markFailedByOrderId(orderId);
    return { status: 'FAILED', paymentId: payment.id };
  }

  return { status: 'PENDING', paymentId: payment.id };
}

// Cashfree webhook handler. Idempotent by construction: markPaidByOrderId
// only transitions CREATED -> PAID, so a redelivered webhook (Cashfree
// retries on anything but a 2xx) is a safe no-op the second time.
async function handleWebhookEvent(payload) {
  const eventType = payload?.type;
  const order = payload?.data?.order;
  const paymentInfo = payload?.data?.payment;

  if (!order?.order_id) {
    logger.warn('cashfree webhook: missing order_id, ignoring', { eventType });
    return;
  }

  if (eventType === 'PAYMENT_SUCCESS_WEBHOOK' || paymentInfo?.payment_status === 'SUCCESS') {
    const updated = await paymentModel.markPaidByOrderId(order.order_id, {
      cfPaymentId: paymentInfo?.cf_payment_id ? String(paymentInfo.cf_payment_id) : undefined,
    });
    if (updated) {
      await auditService.logPayment({
        actorId: updated.user_id,
        action: 'PAYMENT_VERIFIED',
        entityId: updated.id,
        metadata: { cfOrderId: order.order_id, source: 'webhook' },
      });
    }
    return;
  }

  if (
    eventType === 'PAYMENT_FAILED_WEBHOOK' ||
    ['FAILED', 'USER_DROPPED'].includes(paymentInfo?.payment_status)
  ) {
    await paymentModel.markFailedByOrderId(order.order_id);
  }
}

// Used by the matchmaking socket handler: atomically claims a paid,
// unconsumed order for this user. Returns null if the user has no
// verified payment sitting ready — the caller should refuse to enqueue
// them.
async function claimEntryForMatchmaking(userId) {
  return paymentModel.consumeOldestPaidForUser(userId);
}

// Gives a claimed-but-unmatched entry back (queue cancelled, disconnect
// before pairing, or the match failed to form) so the player doesn't lose
// a paid entry they never got to use.
async function releaseUnusedEntry(paymentId) {
  if (!paymentId) return;
  await paymentModel.restoreConsumed(paymentId);
}

// Permanently ties a claimed entry to the match it funded.
async function markEntrySpent(paymentId, matchId) {
  if (!paymentId) return;
  await paymentModel.markSpentForMatch(paymentId, matchId);
}

module.exports = {
  createEntryFeeOrder,
  verifyOrder,
  handleWebhookEvent,
  claimEntryForMatchmaking,
  releaseUnusedEntry,
  markEntrySpent,
};
