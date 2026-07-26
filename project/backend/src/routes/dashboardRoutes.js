const express = require('express');
const dashboardController = require('../controllers/dashboardController');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();

/**
 * @openapi
 * /api/admin/dashboard:
 *   get:
 *     tags: [Admin]
 *     summary: Admin dashboard summary stats
 *     description: >
 *       Headline counters for the admin dashboard: total and currently-active
 *       users, total matches and how many are live right now, and payment
 *       totals (order count and paid revenue). Admin only.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current dashboard stats
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 totalUsers: { type: integer, example: 1520 }
 *                 activeUsers: { type: integer, example: 84, description: Users with a currently valid (non-revoked, non-expired) refresh token }
 *                 totalMatches: { type: integer, example: 3980 }
 *                 liveMatches: { type: integer, example: 6, description: Matches currently in_progress }
 *                 totalPayments: { type: integer, example: 2210, description: Total payment orders of any status }
 *                 paidPayments: { type: integer, example: 2001, description: Payment orders that reached PAID status }
 *                 totalRevenue: { type: number, example: 100050, description: Sum of order_amount for PAID payments }
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.get('/', authenticate, requireAdmin, dashboardController.getDashboardStats);

module.exports = router;
