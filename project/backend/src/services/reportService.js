const matchModel = require('../models/matchModel');
const matchAnswerModel = require('../models/matchAnswerModel');
const questionModel = require('../models/questionModel');
const userModel = require('../models/userModel');
const { ROLES } = require('../constants');

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

// Builds the per-player stats block: accuracy, timing, streaks, and
// breakdowns by category/difficulty. `answersByQuestionId` is this one
// player's own answers, keyed by question_id; `questionsInOrder` is the
// full ordered question set for the match (so we can also count questions
// the player never got an answer row for, e.g. they disconnected early).
function buildPlayerStats(user, answersByQuestionId, questionsInOrder) {
  let correct = 0;
  let incorrect = 0;
  let unanswered = 0;
  let totalAnswerMs = 0;
  let answeredCount = 0;
  let fastestCorrectMs = null;
  let currentStreak = 0;
  let bestStreak = 0;

  const byCategory = {};
  const byDifficulty = {};

  questionsInOrder.forEach((question) => {
    const answer = answersByQuestionId.get(question.id);

    const category = question.category;
    const difficulty = question.difficulty;
    byCategory[category] = byCategory[category] || { correct: 0, total: 0 };
    byDifficulty[difficulty] = byDifficulty[difficulty] || { correct: 0, total: 0 };
    byCategory[category].total += 1;
    byDifficulty[difficulty].total += 1;

    if (!answer) {
      unanswered += 1;
      currentStreak = 0;
      return;
    }

    answeredCount += 1;
    totalAnswerMs += answer.answer_ms;

    if (answer.is_correct) {
      correct += 1;
      byCategory[category].correct += 1;
      byDifficulty[difficulty].correct += 1;
      currentStreak += 1;
      bestStreak = Math.max(bestStreak, currentStreak);
      if (fastestCorrectMs === null || answer.answer_ms < fastestCorrectMs) {
        fastestCorrectMs = answer.answer_ms;
      }
    } else {
      incorrect += 1;
      currentStreak = 0;
    }
  });

  const totalQuestions = questionsInOrder.length;
  const accuracyPct = answeredCount > 0 ? Math.round((correct / answeredCount) * 1000) / 10 : 0;
  const avgAnswerMs = answeredCount > 0 ? Math.round(totalAnswerMs / answeredCount) : null;

  // Strongest/weakest category by accuracy, ignoring categories with no
  // answered questions so a single lucky/unlucky guess doesn't dominate.
  const categoryEntries = Object.entries(byCategory).filter(([, v]) => v.total > 0);
  let strongestCategory = null;
  let weakestCategory = null;
  if (categoryEntries.length > 0) {
    const withRate = categoryEntries.map(([name, v]) => ({
      name,
      ...v,
      rate: v.correct / v.total,
    }));
    strongestCategory = withRate.reduce((a, b) => (b.rate > a.rate ? b : a));
    weakestCategory = withRate.reduce((a, b) => (b.rate < a.rate ? b : a));
  }

  return {
    id: user.id,
    username: user.username,
    name: user.name || user.username,
    score: correct,
    totalQuestions,
    correct,
    incorrect,
    unanswered,
    accuracyPct,
    avgAnswerMs,
    fastestCorrectMs,
    bestStreak,
    byCategory,
    byDifficulty,
    strongestCategory: strongestCategory && { category: strongestCategory.name, correct: strongestCategory.correct, total: strongestCategory.total },
    weakestCategory: weakestCategory && { category: weakestCategory.name, correct: weakestCategory.correct, total: weakestCategory.total },
  };
}

function buildQuestionReview(questionsInOrder, answersA, answersB, playerAId, playerBId) {
  return questionsInOrder.map((question, index) => {
    const options = question.options;
    const answerA = answersA.get(question.id) || null;
    const answerB = answersB.get(question.id) || null;

    const describeAnswer = (answer) => {
      if (!answer) {
        return { chosenIndex: null, chosenText: null, isCorrect: false, answerMs: null, answered: false };
      }
      return {
        chosenIndex: answer.chosen_index,
        chosenText: answer.chosen_index !== null && answer.chosen_index !== undefined
          ? options[answer.chosen_index] ?? null
          : null,
        isCorrect: answer.is_correct,
        answerMs: answer.answer_ms,
        answered: true,
      };
    };

    const aResult = describeAnswer(answerA);
    const bResult = describeAnswer(answerB);

    let fasterCorrectPlayer = null;
    if (aResult.isCorrect && bResult.isCorrect) {
      fasterCorrectPlayer = aResult.answerMs <= bResult.answerMs ? playerAId : playerBId;
    } else if (aResult.isCorrect) {
      fasterCorrectPlayer = playerAId;
    } else if (bResult.isCorrect) {
      fasterCorrectPlayer = playerBId;
    }

    return {
      order: index + 1,
      questionId: question.id,
      category: question.category,
      difficulty: question.difficulty,
      questionText: question.question_text,
      options,
      correctIndex: question.correct_index,
      correctAnswerText: options[question.correct_index] ?? null,
      explanation: question.explanation || null,
      playerA: aResult,
      playerB: bResult,
      fasterCorrectPlayer,
    };
  });
}

async function buildMatchReport(matchId, requestingUser) {
  const match = await matchModel.findById(matchId);
  if (!match) throw httpError('Match not found', 404);

  const isParticipant = match.player_a_id === requestingUser.id || match.player_b_id === requestingUser.id;
  if (!isParticipant && requestingUser.role !== ROLES.ADMIN) {
    throw httpError('Not authorized to view this match', 403);
  }

  const questionIds = Array.isArray(match.question_ids) ? match.question_ids : JSON.parse(match.question_ids);

  const [rawAnswers, rawQuestions, playerA, playerB] = await Promise.all([
    matchAnswerModel.findByMatchId(matchId),
    questionModel.findByIds(questionIds),
    userModel.findPublicById(match.player_a_id),
    userModel.findPublicById(match.player_b_id),
  ]);

  // Preserve the order questions were actually served in during the match.
  const questionsById = new Map(rawQuestions.map((q) => [q.id, q]));
  const questionsInOrder = questionIds.map((id) => questionsById.get(id)).filter(Boolean);

  const answersByPlayer = { [match.player_a_id]: new Map(), [match.player_b_id]: new Map() };
  rawAnswers.forEach((answer) => {
    if (answersByPlayer[answer.user_id]) {
      answersByPlayer[answer.user_id].set(answer.question_id, answer);
    }
  });

  const answersA = answersByPlayer[match.player_a_id];
  const answersB = answersByPlayer[match.player_b_id];

  const statsA = buildPlayerStats(playerA, answersA, questionsInOrder);
  const statsB = buildPlayerStats(playerB, answersB, questionsInOrder);

  let resultA = 'draw';
  let resultB = 'draw';
  if (statsA.score > statsB.score) {
    resultA = 'won';
    resultB = 'lost';
  } else if (statsB.score > statsA.score) {
    resultB = 'won';
    resultA = 'lost';
  }
  statsA.result = resultA;
  statsB.result = resultB;

  const questions = buildQuestionReview(questionsInOrder, answersA, answersB, match.player_a_id, match.player_b_id);

  const fasterAnswerCounts = { [match.player_a_id]: 0, [match.player_b_id]: 0 };
  questions.forEach((q) => {
    if (q.fasterCorrectPlayer) fasterAnswerCounts[q.fasterCorrectPlayer] += 1;
  });

  const durationSeconds = match.completed_at
    ? Math.round((new Date(match.completed_at) - new Date(match.started_at)) / 1000)
    : null;

  return {
    match: {
      id: match.id,
      category: match.category,
      difficulty: match.difficulty,
      questionCount: match.question_count,
      status: match.status,
      startedAt: match.started_at,
      completedAt: match.completed_at,
      durationSeconds,
      winnerId: match.winner_id,
      margin: Math.abs(statsA.score - statsB.score),
    },
    players: {
      playerA: statsA,
      playerB: statsB,
    },
    headToHead: {
      fasterCorrectAnswers: {
        [match.player_a_id]: fasterAnswerCounts[match.player_a_id],
        [match.player_b_id]: fasterAnswerCounts[match.player_b_id],
      },
    },
    questions,
  };
}

module.exports = { buildMatchReport };
