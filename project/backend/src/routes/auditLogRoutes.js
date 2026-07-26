const express = require('express');
const auditLogController = require('../controllers/auditLogController');
const { authenticate, requireAdmin } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { listAuditLogsQuerySchema } = require('../validators/auditLogSchemas');

const router = express.Router();

/**
 * @openapi
 * /api/audit-logs:
 *   get:
 *     tags: [Audit]
 *     summary: List audit log entries (admin only)
 *     description: >
 *       Append-only trail of admin actions, login attempts, payments, and
 *       score changes. Filterable by category/action/status/actor/entity/date
 *       range, and paginated.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema: { type: string, enum: [auth, admin, payment, score] }
 *       - in: query
 *         name: action
 *         schema: { type: string }
 *         example: QUESTION_DELETED
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [success, failure] }
 *       - in: query
 *         name: actorId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: entityType
 *         schema: { type: string }
 *         example: question
 *       - in: query
 *         name: entityId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: from
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: to
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: page
 *         schema: { type: integer, minimum: 1, default: 1 }
 *       - in: query
 *         name: pageSize
 *         schema: { type: integer, default: 50, maximum: 200 }
 *     responses:
 *       200:
 *         description: Matching audit log entries
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 logs:
 *                   type: array
 *                   items: { $ref: '#/components/schemas/AuditLog' }
 *                 total: { type: integer, example: 214 }
 *                 page: { type: integer, example: 1 }
 *                 pageSize: { type: integer, example: 50 }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.get(
  '/',
  authenticate,
  requireAdmin,
  validate({ query: listAuditLogsQuerySchema }),
  auditLogController.listAuditLogs
);

module.exports = router;
