const express = require('express');
const userController = require('../controllers/userController');
const { authenticate, requireAdmin } = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  listUsersQuerySchema,
  searchUsersQuerySchema,
  userIdParamSchema,
  blockUserBodySchema,
  unblockUserBodySchema,
  suspendUserBodySchema,
} = require('../validators/userSchemas');

const router = express.Router();

router.use(authenticate, requireAdmin);

/**
 * @openapi
 * /api/admin/users:
 *   get:
 *     tags: [Users]
 *     summary: List users
 *     description: Paginated user list. Combine with q/role/status query params to filter; equivalent to /search but q is optional here.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema: { type: string }
 *         description: Free-text match against username, email, phone, and name
 *       - in: query
 *         name: role
 *         schema: { type: string, enum: [player, admin] }
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [active, blocked, suspended] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20, maximum: 100 }
 *       - in: query
 *         name: sortBy
 *         schema: { type: string, enum: [created_at, username, status], default: created_at }
 *       - in: query
 *         name: sortOrder
 *         schema: { type: string, enum: [asc, desc], default: desc }
 *     responses:
 *       200:
 *         description: Paginated user list
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/UserListResponse' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.get('/', validate({ query: listUsersQuerySchema }), userController.listUsers);

/**
 * @openapi
 * /api/admin/users/search:
 *   get:
 *     tags: [Users]
 *     summary: Search users
 *     description: Same as GET /api/admin/users but q is required.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema: { type: string }
 *       - in: query
 *         name: role
 *         schema: { type: string, enum: [player, admin] }
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [active, blocked, suspended] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20, maximum: 100 }
 *     responses:
 *       200:
 *         description: Paginated search results
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/UserListResponse' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.get('/search', validate({ query: searchUsersQuerySchema }), userController.searchUsers);

/**
 * @openapi
 * /api/admin/users/{id}:
 *   get:
 *     tags: [Users]
 *     summary: View a user
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: The user
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/User' }
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.get('/:id', validate({ params: userIdParamSchema }), userController.getUser);

/**
 * @openapi
 * /api/admin/users/{id}/block:
 *   post:
 *     tags: [Users]
 *     summary: Block a user
 *     description: Indefinite block. Revokes all active sessions immediately. Cannot be used on admin accounts or on your own account.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/BlockUserRequest' }
 *     responses:
 *       200:
 *         description: Updated user
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/User' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.post(
  '/:id/block',
  validate({ params: userIdParamSchema, body: blockUserBodySchema }),
  userController.blockUser
);

/**
 * @openapi
 * /api/admin/users/{id}/unblock:
 *   post:
 *     tags: [Users]
 *     summary: Unblock a user
 *     description: Restores status to active. Works whether the user was blocked or suspended.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/UnblockUserRequest' }
 *     responses:
 *       200:
 *         description: Updated user
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/User' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.post(
  '/:id/unblock',
  validate({ params: userIdParamSchema, body: unblockUserBodySchema }),
  userController.unblockUser
);

/**
 * @openapi
 * /api/admin/users/{id}/suspend:
 *   post:
 *     tags: [Users]
 *     summary: Suspend a user temporarily
 *     description: Provide exactly one of "days" (relative) or "until" (absolute ISO datetime). Revokes all active sessions immediately.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/SuspendUserRequest' }
 *     responses:
 *       200:
 *         description: Updated user
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/User' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.post(
  '/:id/suspend',
  validate({ params: userIdParamSchema, body: suspendUserBodySchema }),
  userController.suspendUser
);

module.exports = router;
