const { v4: uuidv4 } = require('uuid');
const questionModel = require('../models/questionModel');
const { DIFFICULTIES } = require('../constants');
const cache = require('./cacheService');
const env = require('../config/env');
const auditService = require('./auditService');

const CACHE_NS = 'questions';

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

async function list({ category, difficulty, page = 1, pageSize = 50 }) {
  const limit = Math.min(parseInt(pageSize, 10) || 50, 200);
  const offset = (Math.max(parseInt(page, 10) || 1, 1) - 1) * limit;

  const version = await cache.getVersion(CACHE_NS);
  const cacheKey = `cache:${CACHE_NS}:v${version}:${category || 'any'}:${difficulty || 'any'}:${limit}:${offset}`;

  return cache.wrap(cacheKey, env.cache.questionsTtlSeconds, () =>
    questionModel.list({ category, difficulty, limit, offset })
  );
}

async function create({
  category,
  difficulty,
  questionText,
  options,
  correctIndex,
  explanation,
  createdBy,
  actorUsername,
}) {
  if (!Array.isArray(options) || options.length < 2) {
    throw httpError('options must be an array of at least 2 choices', 400);
  }
  if (!Number.isInteger(correctIndex) || correctIndex < 0 || correctIndex >= options.length) {
    throw httpError('correctIndex must be a valid index into options', 400);
  }
  if (!DIFFICULTIES.includes(difficulty)) {
    throw httpError('difficulty must be Easy, Medium, or Hard', 400);
  }

  const question = await questionModel.create({
    id: uuidv4(),
    category,
    difficulty,
    questionText,
    options,
    correctIndex,
    explanation,
    createdBy,
  });

  await cache.bumpVersion(CACHE_NS); // invalidate cached question lists
  await auditService.logAdminAction({
    actorId: createdBy,
    actorUsername,
    action: 'QUESTION_CREATED',
    entityType: 'question',
    entityId: question.id,
    metadata: { category, difficulty },
  });
  return question;
}

async function bulkCreate(questions, createdBy, actorUsername) {
  if (!Array.isArray(questions) || questions.length === 0) {
    throw httpError('questions must be a non-empty array', 400);
  }

  const ids = [];
  for (const q of questions) {
    const { category, difficulty, questionText, options, correctIndex, explanation } = q;
    if (!Array.isArray(options) || !Number.isInteger(correctIndex)) continue;

    const created = await questionModel.create({
      id: uuidv4(),
      category,
      difficulty,
      questionText,
      options,
      correctIndex,
      explanation,
      createdBy,
    });
    ids.push(created.id);
  }

  if (ids.length > 0) {
    await cache.bumpVersion(CACHE_NS); // one invalidation for the whole batch
    await auditService.logAdminAction({
      actorId: createdBy,
      actorUsername,
      action: 'QUESTIONS_BULK_CREATED',
      entityType: 'question',
      metadata: { insertedCount: ids.length, ids },
    });
  }
  return ids;
}

async function update(id, data, actor = {}) {
  const question = await questionModel.update(id, data);
  if (!question) throw httpError('Question not found', 404);

  await cache.bumpVersion(CACHE_NS);
  await auditService.logAdminAction({
    actorId: actor.id,
    actorUsername: actor.username,
    action: 'QUESTION_UPDATED',
    entityType: 'question',
    entityId: id,
    metadata: { changes: data },
  });
  return question;
}

async function remove(id, actor = {}) {
  await questionModel.remove(id);
  await cache.bumpVersion(CACHE_NS);
  await auditService.logAdminAction({
    actorId: actor.id,
    actorUsername: actor.username,
    action: 'QUESTION_DELETED',
    entityType: 'question',
    entityId: id,
  });
}

module.exports = { list, create, bulkCreate, update, remove };
