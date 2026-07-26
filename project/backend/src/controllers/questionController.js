const questionService = require('../services/questionService');
const asyncHandler = require('../middleware/asyncHandler');

const listQuestions = asyncHandler(async (req, res) => {
  const questions = await questionService.list(req.query);
  res.json({ questions });
});

const createQuestion = asyncHandler(async (req, res) => {
  const question = await questionService.create({
    ...req.body,
    createdBy: req.user.id,
    actorUsername: req.user.username,
  });
  res.status(201).json({ question });
});

const bulkCreateQuestions = asyncHandler(async (req, res) => {
  const ids = await questionService.bulkCreate(req.body.questions, req.user.id, req.user.username);
  res.status(201).json({ insertedCount: ids.length, ids });
});

const updateQuestion = asyncHandler(async (req, res) => {
  const question = await questionService.update(req.params.id, req.body, {
    id: req.user.id,
    username: req.user.username,
  });
  res.json({ question });
});

const deleteQuestion = asyncHandler(async (req, res) => {
  await questionService.remove(req.params.id, { id: req.user.id, username: req.user.username });
  res.json({ success: true });
});

module.exports = {
  listQuestions,
  createQuestion,
  bulkCreateQuestions,
  updateQuestion,
  deleteQuestion,
};
