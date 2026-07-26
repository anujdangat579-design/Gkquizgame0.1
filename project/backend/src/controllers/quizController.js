const quizService = require('../services/quizService');
const reportService = require('../services/reportService');
const asyncHandler = require('../middleware/asyncHandler');

const getLeaderboard = asyncHandler(async (req, res) => {
  const leaderboard = await quizService.getLeaderboard(req.query.limit, req.query.period);
  res.json({ leaderboard });
});

const getMyMatchHistory = asyncHandler(async (req, res) => {
  const matches = await quizService.getMyMatches(req.user.id);
  res.json({ matches });
});

const getMatchById = asyncHandler(async (req, res) => {
  const { match, answers } = await quizService.getMatchDetail(req.params.id, req.user);
  res.json({ match, answers });
});

const getMatchReport = asyncHandler(async (req, res) => {
  const report = await reportService.buildMatchReport(req.params.id, req.user);
  res.json({ report });
});

module.exports = { getLeaderboard, getMyMatchHistory, getMatchById, getMatchReport };
