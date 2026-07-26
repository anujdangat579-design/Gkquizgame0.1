const { v4: uuidv4 } = require('uuid');
const questionModel = require('../models/questionModel');
const matchModel = require('../models/matchModel');
const matchAnswerModel = require('../models/matchAnswerModel');
const leaderboardModel = require('../models/leaderboardModel');
const {
  QUESTION_TIME_LIMIT_MS,
  NEXT_QUESTION_DELAY_MS,
  COUNTDOWN_START_SECONDS,
  COUNTDOWN_TICK_MS,
} = require('../constants');
const cache = require('./cacheService');
const auditService = require('./auditService');
const paymentService = require('./paymentService');
const logger = require('../config/logger');

// Active in-memory match state, keyed by matchId. Persisted results are
// written to Postgres as the match progresses / completes.
const activeMatches = new Map();

// Defense-in-depth against duplicate room creation: sockets/index.js is the
// primary guard (it deletes the pending-match entry and flips a
// roomCreating flag synchronously before ever calling in here), but keeping
// a same-pair lock at this layer too means even a stray double-call for the
// same two users during the async window between "both accepted" and
// "match row inserted" can't create two rooms.
const activePairLocks = new Set();

function pairKey(userIdA, userIdB) {
  return [userIdA, userIdB].sort().join(':');
}

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

// Shuffles a question's options once, server-side, and remaps correct_index
// to match — the exact same shuffled order is what both players receive
// (built once here, broadcast to the room), and correctness checks later
// keep working unmodified since correct_index now points at the new
// position. The original ordering/answer is never sent to either client.
function shuffleQuestionOptions(q) {
  const options = Array.isArray(q.options) ? q.options : JSON.parse(q.options);
  const order = options.map((_, i) => i);
  for (let i = order.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [order[i], order[j]] = [order[j], order[i]];
  }
  return {
    ...q,
    options: order.map((originalIndex) => options[originalIndex]),
    correct_index: order.indexOf(q.correct_index),
  };
}

// Called once both matched players have explicitly accepted (sockets/index.js
// owns that handshake and guarantees this only runs once per pair). Builds
// the secure quiz room: generates the match id, locks both verified
// payments to it, picks and shuffles the question set, sends the identical
// set to both players, then starts the synchronized countdown and the
// first question's server-side timer.
//
// Deliberately does NOT touch scoring — submitAnswer's existing logic is
// left as-is; it keeps working unmodified because shuffleQuestionOptions
// remaps correct_index to the shuffled position before it's ever stored.
//
// Returns the new matchId, or null if the room could not be created (in
// which case both entries have already been released and both sockets
// already notified).
async function createMatch(io, { playerA, playerB, criteria }) {
  const key = pairKey(playerA.userId, playerB.userId);
  if (activePairLocks.has(key)) {
    logger.warn('quizRoomService: duplicate createMatch call for an already-locked pair, ignoring', {
      playerAId: playerA.userId,
      playerBId: playerB.userId,
    });
    return null;
  }
  activePairLocks.add(key);

  try {
    const questions = await questionModel.pickRandomForMatch(criteria);
    if (questions.length < criteria.questionCount) {
      // Not enough questions in the bank for this configuration — nobody got
      // to play, so hand both paid entries back instead of spending them.
      await Promise.all([
        paymentService.releaseUnusedEntry(playerA.paymentId),
        paymentService.releaseUnusedEntry(playerB.paymentId),
      ]);
      io.to(playerA.socketId).emit('matchmaking:failed', { reason: 'insufficient_questions' });
      io.to(playerB.socketId).emit('matchmaking:failed', { reason: 'insufficient_questions' });
      return null;
    }

    const matchId = uuidv4();

    // Lock both verified payments to this match now, before the room is
    // usable — from this point a disconnect/abandon can no longer un-claim
    // either entry (see paymentModel.restoreConsumed's match_id IS NULL guard).
    await Promise.all([
      paymentService.markEntrySpent(playerA.paymentId, matchId),
      paymentService.markEntrySpent(playerB.paymentId, matchId),
    ]);

    await matchModel.create({
      id: matchId,
      playerAId: playerA.userId,
      playerBId: playerB.userId,
      category: criteria.category,
      difficulty: criteria.difficulty,
      questionCount: criteria.questionCount,
      questionIds: questions.map((q) => q.id),
    });

    // Randomize each question's answer order once — the same shuffled order
    // is what both players get, since it's built here and broadcast once.
    const shuffledQuestions = questions.map(shuffleQuestionOptions);

    const state = {
      matchId,
      questions: shuffledQuestions,
      currentIndex: 0,
      scores: {
        [playerA.userId]: { correct: 0, total: 0, username: playerA.username, socketId: playerA.socketId },
        [playerB.userId]: { correct: 0, total: 0, username: playerB.username, socketId: playerB.socketId },
      },
      answersThisQuestion: new Set(),
      questionStartedAt: null,
      timer: null,
      countdownTimer: null,
    };
    activeMatches.set(matchId, state);

    const roomName = `match:${matchId}`;
    io.sockets.sockets.get(playerA.socketId)?.join(roomName);
    io.sockets.sockets.get(playerB.socketId)?.join(roomName);

    // Same question set (sanitized — no correct answers) sent identically
    // to both players in one broadcast, before anything else happens.
    io.to(roomName).emit('match:roomCreated', {
      matchId,
      opponents: {
        [playerA.userId]: playerA.username,
        [playerB.userId]: playerB.username,
      },
      category: criteria.category,
      difficulty: criteria.difficulty,
      questionCount: criteria.questionCount,
      questions: shuffledQuestions.map((q, i) => sanitizeQuestion(q, i, shuffledQuestions.length)),
    });

    startCountdown(io, matchId);

    return matchId;
  } finally {
    activePairLocks.delete(key);
  }
}

// Synchronized 3...2...1 countdown broadcast to the room, then hands off to
// sendNextQuestion (which starts question 1's server-side timer). Bails
// cleanly if the room gets torn down mid-countdown (e.g. a disconnect).
function startCountdown(io, matchId) {
  const roomName = `match:${matchId}`;
  let count = COUNTDOWN_START_SECONDS;

  const tick = () => {
    const state = activeMatches.get(matchId);
    if (!state) return;

    if (count > 0) {
      io.to(roomName).emit('match:countdown', { count, matchId });
      count -= 1;
      state.countdownTimer = setTimeout(tick, COUNTDOWN_TICK_MS);
    } else {
      io.to(roomName).emit('match:countdownComplete', { matchId });
      sendNextQuestion(io, matchId);
    }
  };

  tick();
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

  io.to(`match:${matchId}`).emit('match:question', {
    ...sanitizeQuestion(q, state.currentIndex, state.questions.length),
    // Server-authoritative deadline: clients render their countdown against
    // `endsAt` (this server's clock), not a locally-started timer, so a
    // slow/fast client clock or a late-joining render can't drift from what
    // the server will actually enforce below.
    serverTime: state.questionStartedAt,
    timeLimitMs: QUESTION_TIME_LIMIT_MS,
    endsAt: state.questionStartedAt + QUESTION_TIME_LIMIT_MS,
  });

  clearTimeout(state.timer);
  state.timer = setTimeout(() => {
    advanceQuestion(io, matchId);
  }, QUESTION_TIME_LIMIT_MS);
}

async function submitAnswer(io, { matchId, userId, questionIndex, chosenIndex }) {
  const state = activeMatches.get(matchId);
  if (!state) return { error: 'Match not found or already ended' };
  if (!state.scores[userId]) return { error: 'You are not a player in this match' };

  // The client tells us which question it *thinks* is current; the server
  // is the one that decides whether that's still true. Without this check,
  // an answer that arrives just after the timer already fired (during the
  // brief gap before the next question is sent) would silently get graded
  // against whatever question is current by the time it's processed —
  // i.e. the wrong one. Rejecting a stale/mismatched index instead of
  // guessing is what makes the timer server-authoritative rather than
  // advisory.
  if (Number(questionIndex) !== state.currentIndex) {
    return { error: 'This question has already closed', code: 'QUESTION_CLOSED' };
  }
  if (state.answersThisQuestion.has(userId)) return { error: 'Already answered this question' };

  const q = state.questions[state.currentIndex];
  const isCorrect = Number(chosenIndex) === q.correct_index;
  const answerMs = Date.now() - state.questionStartedAt;

  state.answersThisQuestion.add(userId);
  state.scores[userId].total += 1;
  if (isCorrect) state.scores[userId].correct += 1;

  await matchAnswerModel.create({
    id: uuidv4(),
    matchId,
    userId,
    questionId: q.id,
    chosenIndex: Number.isInteger(chosenIndex) ? chosenIndex : null,
    isCorrect,
    answerMs,
  });

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
  setTimeout(() => sendNextQuestion(io, matchId), NEXT_QUESTION_DELAY_MS);
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

  await matchModel.markCompleted({ id: matchId, winnerId, scoreA: scoreA.correct, scoreB: scoreB.correct });

  for (const uid of userIds) {
    const s = state.scores[uid];
    await leaderboardModel.upsertAfterMatch({
      userId: uid,
      won: winnerId === uid,
      correct: s.correct,
      total: s.total,
    });
  }

  await cache.bumpVersion('leaderboard'); // stats changed — invalidate cached /api/quiz/leaderboard reads

  await auditService.logScoreChange({
    action: 'MATCH_COMPLETED',
    entityId: matchId,
    metadata: {
      winnerId,
      scores: {
        [uidA]: { correct: scoreA.correct, total: scoreA.total },
        [uidB]: { correct: scoreB.correct, total: scoreB.total },
      },
    },
  });

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
  clearTimeout(state.countdownTimer);
  const otherUserId = Object.keys(state.scores).find((id) => id !== userId);

  await matchModel.markAbandoned({ id: matchId, winnerId: otherUserId });

  await auditService.logScoreChange({
    action: 'MATCH_ABANDONED',
    entityId: matchId,
    metadata: { disconnectedUserId: userId, remainingUserId: otherUserId },
  });

  io.to(`match:${matchId}`).emit('match:opponentLeft', { matchId, remainingUserId: otherUserId });
  activeMatches.delete(matchId);
}

module.exports = { createMatch, submitAnswer, handleDisconnect, activeMatches };
