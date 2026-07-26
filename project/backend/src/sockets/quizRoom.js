const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

const QUESTION_TIME_LIMIT_MS = 15000;

// Active in-memory match state, keyed by matchId. Persisted results are
// written to Postgres as the match progresses / completes.
const activeMatches = new Map();

function sanitizeQuestion(q, index, total) {
  // Never send correct_index to clients.
  return {
    index,
    total,
    id: q.id,
    category: q.category,
    difficulty: q.difficulty,
    questionText: q.question_text,
    options: q.options,
  };
}

async function pickQuestions({ category, difficulty, questionCount }) {
  const params = [difficulty];
  let categoryClause = '';
  if (category) {
    params.push(category);
    categoryClause = 'AND category = $2';
  }
  params.push(questionCount);

  const result = await db.query(
    `SELECT * FROM questions
     WHERE is_active = TRUE AND difficulty = $1 ${categoryClause}
     ORDER BY RANDOM()
     LIMIT $${params.length}`,
    params
  );
  return result.rows;
}

async function createMatch(io, { playerA, playerB, criteria }) {
  const questions = await pickQuestions(criteria);
  if (questions.length < criteria.questionCount) {
    // Not enough questions in the bank for this configuration.
    io.to(playerA.socketId).emit('matchmaking:failed', { reason: 'insufficient_questions' });
    io.to(playerB.socketId).emit('matchmaking:failed', { reason: 'insufficient_questions' });
    return;
  }

  const matchId = uuidv4();
  await db.query(
    `INSERT INTO matches (id, player_a_id, player_b_id, category, difficulty, question_count, question_ids, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'in_progress')`,
    [
      matchId,
      playerA.userId,
      playerB.userId,
      criteria.category || null,
      criteria.difficulty,
      criteria.questionCount,
      JSON.stringify(questions.map((q) => q.id)),
    ]
  );

  const state = {
    matchId,
    questions,
    currentIndex: 0,
    scores: {
      [playerA.userId]: { correct: 0, total: 0, username: playerA.username, socketId: playerA.socketId },
      [playerB.userId]: { correct: 0, total: 0, username: playerB.username, socketId: playerB.socketId },
    },
    answersThisQuestion: new Set(),
    questionStartedAt: null,
    timer: null,
  };
  activeMatches.set(matchId, state);

  const roomName = `match:${matchId}`;
  io.sockets.sockets.get(playerA.socketId)?.join(roomName);
  io.sockets.sockets.get(playerB.socketId)?.join(roomName);

  io.to(roomName).emit('match:found', {
    matchId,
    opponents: {
      [playerA.userId]: playerA.username,
      [playerB.userId]: playerB.username,
    },
    difficulty: criteria.difficulty,
    category: criteria.category,
    questionCount: criteria.questionCount,
  });

  sendNextQuestion(io, matchId);
}

function sendNextQuestion(io, matchId) {
  const state = activeMatches.get(matchId);
  if (!state) return;

  if (state.currentIndex >= state.questions.length) {
    return finishMatch(io, matchId);
  }

  state.answersThisQuestion = new Set();
  state.questionStartedAt = Date.now();
  const q = state.questions[state.currentIndex];

  io.to(`match:${matchId}`).emit(
    'match:question',
    sanitizeQuestion(q, state.currentIndex, state.questions.length)
  );

  clearTimeout(state.timer);
  state.timer = setTimeout(() => {
    advanceQuestion(io, matchId);
  }, QUESTION_TIME_LIMIT_MS);
}

async function submitAnswer(io, { matchId, userId, chosenIndex }) {
  const state = activeMatches.get(matchId);
  if (!state) return { error: 'Match not found or already ended' };
  if (!state.scores[userId]) return { error: 'You are not a player in this match' };
  if (state.answersThisQuestion.has(userId)) return { error: 'Already answered this question' };

  const q = state.questions[state.currentIndex];
  const isCorrect = Number(chosenIndex) === q.correct_index;
  const answerMs = Date.now() - state.questionStartedAt;

  state.answersThisQuestion.add(userId);
  state.scores[userId].total += 1;
  if (isCorrect) state.scores[userId].correct += 1;

  await db.query(
    `INSERT INTO match_answers (id, match_id, user_id, question_id, chosen_index, is_correct, answer_ms)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [uuidv4(), matchId, userId, q.id, Number.isInteger(chosenIndex) ? chosenIndex : null, isCorrect, answerMs]
  );

  io.to(`match:${matchId}`).emit('match:answerReceived', { userId, questionIndex: state.currentIndex });

  // If both players answered, move on immediately instead of waiting for the timer.
  if (state.answersThisQuestion.size >= 2) {
    clearTimeout(state.timer);
    advanceQuestion(io, matchId);
  }

  return { success: true, isCorrect };
}

function advanceQuestion(io, matchId) {
  const state = activeMatches.get(matchId);
  if (!state) return;

  const q = state.questions[state.currentIndex];
  io.to(`match:${matchId}`).emit('match:questionResult', {
    questionIndex: state.currentIndex,
    correctIndex: q.correct_index,
    explanation: q.explanation || null,
  });

  state.currentIndex += 1;
  setTimeout(() => sendNextQuestion(io, matchId), 2000); // brief pause to show the answer
}

async function finishMatch(io, matchId) {
  const state = activeMatches.get(matchId);
  if (!state) return;

  const userIds = Object.keys(state.scores);
  const [uidA, uidB] = userIds;
  const scoreA = state.scores[uidA];
  const scoreB = state.scores[uidB];

  let winnerId = null;
  if (scoreA.correct > scoreB.correct) winnerId = uidA;
  else if (scoreB.correct > scoreA.correct) winnerId = uidB;
  // null winnerId means a tie — no winner, no loser, purely educational outcome.

  await db.query(
    `UPDATE matches SET status = 'completed', winner_id = $1, score_a = $2, score_b = $3, completed_at = now()
     WHERE id = $4`,
    [winnerId, scoreA.correct, scoreB.correct, matchId]
  );

  for (const uid of userIds) {
    const s = state.scores[uid];
    const won = winnerId === uid;
    await db.query(
      `INSERT INTO leaderboard_stats (user_id, matches_played, matches_won, total_correct, total_answered, updated_at)
       VALUES ($1, 1, $2, $3, $4, now())
       ON CONFLICT (user_id) DO UPDATE SET
         matches_played = leaderboard_stats.matches_played + 1,
         matches_won = leaderboard_stats.matches_won + $2,
         total_correct = leaderboard_stats.total_correct + $3,
         total_answered = leaderboard_stats.total_answered + $4,
         updated_at = now()`,
      [uid, won ? 1 : 0, s.correct, s.total]
    );
  }

  io.to(`match:${matchId}`).emit('match:finished', {
    matchId,
    winnerId,
    scores: {
      [uidA]: { username: scoreA.username, correct: scoreA.correct, total: scoreA.total },
      [uidB]: { username: scoreB.username, correct: scoreB.correct, total: scoreB.total },
    },
  });

  activeMatches.delete(matchId);
}

async function handleDisconnect(io, matchId, userId) {
  const state = activeMatches.get(matchId);
  if (!state) return;

  clearTimeout(state.timer);
  const otherUserId = Object.keys(state.scores).find((id) => id !== userId);

  await db.query(
    `UPDATE matches SET status = 'abandoned', winner_id = $1, completed_at = now() WHERE id = $2`,
    [otherUserId || null, matchId]
  );

  io.to(`match:${matchId}`).emit('match:opponentLeft', { matchId, remainingUserId: otherUserId });
  activeMatches.delete(matchId);
}

module.exports = { createMatch, submitAnswer, handleDisconnect, activeMatches };
