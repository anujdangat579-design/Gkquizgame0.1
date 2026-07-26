const express = require('express');
const quizController = require('../controllers/quizController');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { idParamSchema } = require('../validators/commonSchemas');
const { leaderboardQuerySchema } = require('../validators/quizSchemas');

const router = express.Router();

/**
 * @openapi
 * /api/quiz/leaderboard:
 *   get:
 *     tags: [Quiz]
 *     summary: Get the leaderboard
 *     description: >
 *       Without `period`, returns the classic all-time leaderboard ranked by
 *       matches won then total correct answers (unchanged legacy shape).
 *       With `period` set, returns a leaderboard ranked by score (total
 *       correct answers in that window) then accuracy, computed for that
 *       specific window — 'daily' (since UTC midnight today), 'weekly'
 *       (since this ISO week's Monday), 'monthly' (since the 1st of the
 *       current UTC month), or 'all_time' (full history, same window as
 *       default but reshaped with accuracyPct included).
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 50, maximum: 200 }
 *       - in: query
 *         name: period
 *         schema: { type: string, enum: [daily, weekly, monthly, all_time] }
 *     responses:
 *       200:
 *         description: Leaderboard entries
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 leaderboard:
 *                   type: array
 *                   items: { $ref: '#/components/schemas/LeaderboardEntry' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get(
  '/leaderboard',
  authenticate,
  validate({ query: leaderboardQuerySchema }),
  quizController.getLeaderboard
);

/**
 * @openapi
 * /api/quiz/matches/mine:
 *   get:
 *     tags: [Quiz]
 *     summary: Get the current user's match history
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: The user's matches
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 matches:
 *                   type: array
 *                   items: { $ref: '#/components/schemas/Match' }
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/matches/mine', authenticate, quizController.getMyMatchHistory);

/**
 * @openapi
 * /api/quiz/matches/{id}:
 *   get:
 *     tags: [Quiz]
 *     summary: Get full detail for a single match
 *     description: Only a participant in the match, or an admin, may view it.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Match and its answers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 match: { $ref: '#/components/schemas/Match' }
 *                 answers:
 *                   type: array
 *                   items: { $ref: '#/components/schemas/MatchAnswer' }
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.get('/matches/:id', authenticate, validate({ params: idParamSchema }), quizController.getMatchById);

/**
 * @openapi
 * /api/quiz/matches/{id}/report:
 *   get:
 *     tags: [Quiz]
 *     summary: Get a detailed head-to-head score report for a match
 *     description: >
 *       Includes per-player performance analysis (accuracy, average answer time,
 *       best streak, category/difficulty breakdowns) and a full question-by-question
 *       review with each player's chosen answer, the correct answer, and its explanation.
 *       Only a participant in the match, or an admin, may view it.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: The detailed score report
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         $ref: '#/components/responses/Forbidden'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.get(
  '/matches/:id/report',
  authenticate,
  validate({ params: idParamSchema }),
  quizController.getMatchReport
);

module.exports = router;
