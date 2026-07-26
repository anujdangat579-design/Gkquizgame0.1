const express = require('express');
const questionController = require('../controllers/questionController');
const { authenticate, requireAdmin } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { idParamSchema } = require('../validators/commonSchemas');
const {
  createQuestionSchema,
  bulkCreateQuestionSchema,
  updateQuestionSchema,
  listQuestionsQuerySchema,
} = require('../validators/questionSchemas');

const router = express.Router();

/**
 * @openapi
 * /api/questions:
 *   get:
 *     tags: [Questions]
 *     summary: List questions
 *     description: Paginated, optionally filtered by category and/or difficulty. Results are cached briefly server-side.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema: { type: string }
 *         example: Geography
 *       - in: query
 *         name: difficulty
 *         schema: { type: string, enum: [Easy, Medium, Hard] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, minimum: 1, default: 1 }
 *       - in: query
 *         name: pageSize
 *         schema: { type: integer, default: 50, maximum: 200 }
 *     responses:
 *       200:
 *         description: Matching questions
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 questions:
 *                   type: array
 *                   items: { $ref: '#/components/schemas/Question' }
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get(
  '/',
  authenticate,
  validate({ query: listQuestionsQuerySchema }),
  questionController.listQuestions
);

/**
 * @openapi
 * /api/questions:
 *   post:
 *     tags: [Questions]
 *     summary: Create a question (admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/QuestionInput'
 *     responses:
 *       201:
 *         description: Question created
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 question: { $ref: '#/components/schemas/Question' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.post(
  '/',
  authenticate,
  requireAdmin,
  validate({ body: createQuestionSchema }),
  questionController.createQuestion
);

/**
 * @openapi
 * /api/questions/bulk:
 *   post:
 *     tags: [Questions]
 *     summary: Create many questions at once (admin only)
 *     description: The whole batch is validated up front — if any entry is malformed, the entire request is rejected with a 400 and no questions are created.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/BulkQuestionInput'
 *     responses:
 *       201:
 *         description: Questions created
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 insertedCount: { type: integer, example: 8 }
 *                 ids:
 *                   type: array
 *                   items: { type: string, format: uuid }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.post(
  '/bulk',
  authenticate,
  requireAdmin,
  validate({ body: bulkCreateQuestionSchema }),
  questionController.bulkCreateQuestions
);

/**
 * @openapi
 * /api/questions/{id}:
 *   patch:
 *     tags: [Questions]
 *     summary: Partially update a question (admin only)
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
 *           schema:
 *             type: object
 *             description: All fields optional; only supplied fields are updated.
 *             properties:
 *               category: { type: string }
 *               difficulty: { type: string, enum: [Easy, Medium, Hard] }
 *               questionText: { type: string, minLength: 3 }
 *               options: { type: array, items: { type: string } }
 *               correctIndex: { type: integer, minimum: 0 }
 *               explanation: { type: string }
 *     responses:
 *       200:
 *         description: Updated question
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 question: { $ref: '#/components/schemas/Question' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.patch(
  '/:id',
  authenticate,
  requireAdmin,
  validate({ params: idParamSchema, body: updateQuestionSchema }),
  questionController.updateQuestion
);

/**
 * @openapi
 * /api/questions/{id}:
 *   delete:
 *     tags: [Questions]
 *     summary: Delete a question (admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Deleted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success: { type: boolean, example: true }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 */
router.delete(
  '/:id',
  authenticate,
  requireAdmin,
  validate({ params: idParamSchema }),
  questionController.deleteQuestion
);

module.exports = router;
