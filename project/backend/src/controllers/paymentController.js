const paymentService = require('../services/paymentService');
const cashfreeService = require('../services/cashfreeService');
const asyncHandler = require('../middleware/asyncHandler');
const logger = require('../config/logger');

const createOrder = asyncHandler(async (req, res) => {
  const order = await paymentService.createEntryFeeOrder(req.user, req.body);
  res.status(201).json({ order });
});

const verifyOrder = asyncHandler(async (req, res) => {
  const result = await paymentService.verifyOrder(req.params.orderId, req.user.id);
  res.json(result);
});

// Cashfree POSTs here on every payment lifecycle event for orders we
// created. No `authenticate` middleware — Cashfree isn't one of our users —
// trust is established purely via the HMAC signature below. Always
// responds 200 once the signature checks out (even for event types we
// don't act on) so Cashfree doesn't keep retrying; a bad/missing signature
// gets a 401 so a spoofed request never touches paymentService.
const webhook = asyncHandler(async (req, res) => {
  const signature = req.headers['x-webhook-signature'];
  const timestamp = req.headers['x-webhook-timestamp'];
  const rawBody = req.rawBody ? req.rawBody.toString('utf8') : '';

  const valid = cashfreeService.verifyWebhookSignature({ rawBody, timestamp, signature });
  if (!valid) {
    logger.warn('cashfree webhook: signature verification failed');
    return res.status(401).json({ error: 'Invalid webhook signature' });
  }

  await paymentService.handleWebhookEvent(req.body);
  res.status(200).json({ received: true });
});

module.exports = { createOrder, verifyOrder, webhook };
