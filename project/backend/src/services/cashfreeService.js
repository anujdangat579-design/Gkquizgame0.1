const crypto = require('crypto');
const env = require('../config/env');
const logger = require('../config/logger');

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

function assertConfigured() {
  if (!env.cashfree.appId || !env.cashfree.secretKey) {
    throw httpError('Payments are not configured on this server', 500);
  }
}

function authHeaders() {
  return {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    'x-client-id': env.cashfree.appId,
    'x-client-secret': env.cashfree.secretKey,
    'x-api-version': env.cashfree.apiVersion,
  };
}

// Creates a Cashfree order and returns the payment_session_id the client
// SDK (Drop-in / mobile) needs to actually collect payment. cfOrderId is
// ours (we generate it) so it can double as the primary correlation key
// between our `payments` row and Cashfree's order.
async function createOrder({ cfOrderId, amount, currency, customer, returnUrl }) {
  assertConfigured();

  const body = {
    order_id: cfOrderId,
    order_amount: Number(amount),
    order_currency: currency,
    customer_details: {
      customer_id: customer.id,
      customer_name: customer.name || customer.username,
      customer_email: customer.email || `${customer.username}@example.invalid`,
      customer_phone: customer.phone || '9999999999',
    },
    order_meta: {
      ...(returnUrl ? { return_url: `${returnUrl}?order_id={order_id}` } : {}),
      ...(env.cashfree.notifyUrl ? { notify_url: env.cashfree.notifyUrl } : {}),
    },
  };

  let response;
  try {
    response = await fetch(`${env.cashfree.baseUrl}/orders`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify(body),
    });
  } catch (err) {
    logger.error('cashfree: createOrder network error', { message: err.message });
    throw httpError('Could not reach the payment gateway', 502);
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    logger.error('cashfree: createOrder failed', { status: response.status, data });
    throw httpError(data?.message || 'Failed to create payment order', 502);
  }

  return {
    cfOrderId: data.order_id,
    orderStatus: data.order_status,
    paymentSessionId: data.payment_session_id,
  };
}

// Server-to-server status check — used as a fallback right after the client
// reports payment completion, in case the webhook hasn't landed yet.
async function fetchOrder(cfOrderId) {
  assertConfigured();

  let response;
  try {
    response = await fetch(`${env.cashfree.baseUrl}/orders/${encodeURIComponent(cfOrderId)}`, {
      method: 'GET',
      headers: authHeaders(),
    });
  } catch (err) {
    logger.error('cashfree: fetchOrder network error', { message: err.message });
    throw httpError('Could not reach the payment gateway', 502);
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    if (response.status === 404) {
      throw httpError('Order not found', 404);
    }
    logger.error('cashfree: fetchOrder failed', { status: response.status, data });
    throw httpError(data?.message || 'Failed to fetch order status', 502);
  }

  return {
    cfOrderId: data.order_id,
    orderStatus: data.order_status, // 'ACTIVE' | 'PAID' | 'EXPIRED' | 'TERMINATED' ...
    cfPaymentId: data.cf_order_id,
  };
}

// Verifies the `x-webhook-signature` header Cashfree sends on every webhook
// POST: base64(HMAC-SHA256(timestamp + rawBody, webhookSecret)). Requires
// the *raw, unparsed* request body — see app.js's express.json({ verify })
// hook, which stashes it on req.rawBody before JSON-parsing the request.
function verifyWebhookSignature({ rawBody, timestamp, signature }) {
  if (!env.cashfree.webhookSecret) {
    logger.error('cashfree: webhook received but no webhook secret is configured');
    return false;
  }
  if (!rawBody || !timestamp || !signature) return false;

  const expected = crypto
    .createHmac('sha256', env.cashfree.webhookSecret)
    .update(timestamp + rawBody)
    .digest('base64');

  const expectedBuf = Buffer.from(expected);
  const actualBuf = Buffer.from(signature);
  if (expectedBuf.length !== actualBuf.length) return false;
  return crypto.timingSafeEqual(expectedBuf, actualBuf);
}

module.exports = { createOrder, fetchOrder, verifyWebhookSignature };
