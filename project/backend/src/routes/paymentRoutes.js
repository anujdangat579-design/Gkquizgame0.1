const express = require('express');
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { createOrderSchema, orderIdParamSchema } = require('../validators/paymentSchemas');

const router = express.Router();

/**
 * @openapi
 * /api/payments/orders:
 *   post:
 *     tags: [Payments]
 *     summary: Create a Cashfree order for the matchmaking entry fee
 *     description: >
 *       Opens a Cashfree order for the server-configured flat entry fee and
 *       returns a payment_session_id for the client to open Cashfree
 *       checkout with. The order starts in CREATED status — it isn't usable
 *       to join matchmaking until Cashfree confirms payment (webhook, or a
 *       follow-up call to /api/payments/orders/{orderId}/verify).
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               category: { type: string, nullable: true }
 *               difficulty: { type: string, enum: [Easy, Medium, Hard] }
 *               questionCount: { type: integer, enum: [10, 20, 30] }
 *     responses:
 *       201:
 *         description: Order created
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       502:
 *         description: Cashfree could not be reached or rejected the order
 */
router.post('/orders', authenticate, validate({ body: createOrderSchema }), paymentController.createOrder);

/**
 * @openapi
 * /api/payments/orders/{orderId}/verify:
 *   get:
 *     tags: [Payments]
 *     summary: Re-check an order's payment status directly with Cashfree
 *     description: >
 *       Fast-path check for right after checkout closes — the webhook is
 *       still the source of truth but can lag by a few seconds. Only
 *       returns PAID once Cashfree itself confirms it.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Current status — PAID, PENDING, or FAILED
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.get(
  '/orders/:orderId/verify',
  authenticate,
  validate({ params: orderIdParamSchema }),
  paymentController.verifyOrder
);

/**
 * @openapi
 * /api/payments/webhook:
 *   post:
 *     tags: [Payments]
 *     summary: Cashfree server-to-server payment webhook
 *     description: >
 *       Called by Cashfree, not by app clients. Authenticated by HMAC
 *       signature (x-webhook-signature / x-webhook-timestamp headers), not
 *       a bearer token.
 *     security: []
 *     responses:
 *       200:
 *         description: Event processed (or ignored, if not one we act on)
 *       401:
 *         description: Signature missing or invalid
 */
router.post('/webhook', paymentController.webhook);

module.exports = router;
