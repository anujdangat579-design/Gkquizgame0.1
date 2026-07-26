const { v4: uuidv4 } = require('uuid');
const socketAuth = require('./socketAuth');
const matchmakingService = require('../services/matchmakingService');
const quizRoomService = require('../services/quizRoomService');
const paymentService = require('../services/paymentService');
const userModel = require('../models/userModel');
const { DIFFICULTIES, QUESTION_COUNT_OPTIONS, MATCH_ACCEPT_TIMEOUT_MS } = require('../constants');
const logger = require('../config/logger');

// Tracks which matchId a given socket/user is currently in, so we can
// clean up properly on disconnect.
const socketMatch = new Map(); // socketId -> matchId

// Tracks the paid-entry payment id a socket has claimed — while waiting in
// the matchmaking queue, and still while waiting on the accept handshake
// (since quiz-room creation, which permanently spends the entry, only
// happens once both sides have accepted). Cleared the moment the entry is
// released (cancel/disconnect/decline) or actually spent by room creation.
const socketPendingPayment = new Map(); // socketId -> paymentId

// A pending match is a pair that matchmaking has paired but who haven't
// both accepted yet. Keyed by a one-off pendingId (distinct from the real
// matchId, which is only generated once the room is actually created).
const pendingMatches = new Map(); // pendingId -> { playerA, playerB, criteria, accepted, acceptTimer, roomCreating }
const userPendingMatch = new Map(); // userId -> pendingId, for O(1) lookup on cancel/disconnect

function otherPlayer(pending, userId) {
  return pending.playerA.userId === userId ? pending.playerB : pending.playerA;
}

function initSockets(io) {
  io.use(socketAuth);

  // Tears down a not-yet-accepted pending match: clears its timer, releases
  // both claimed payments back (nobody spent anything, so nobody should
  // lose their entry), and lets both sides know. Safe to call multiple
  // times / after roomCreating has already flipped — it just no-ops.
  async function cancelPendingMatch(pendingId, { notifyEvent } = {}) {
    const pending = pendingMatches.get(pendingId);
    if (!pending || pending.roomCreating) return;

    pendingMatches.delete(pendingId);
    userPendingMatch.delete(pending.playerA.userId);
    userPendingMatch.delete(pending.playerB.userId);
    clearTimeout(pending.acceptTimer);
    socketPendingPayment.delete(pending.playerA.socketId);
    socketPendingPayment.delete(pending.playerB.socketId);

    await Promise.all([
      paymentService.releaseUnusedEntry(pending.playerA.paymentId),
      paymentService.releaseUnusedEntry(pending.playerB.paymentId),
    ]);

    if (notifyEvent) {
      io.to(pending.playerA.socketId).emit(notifyEvent);
      io.to(pending.playerB.socketId).emit(notifyEvent);
    }
  }

  io.on('connection', (socket) => {
    const { id: userId, username } = socket.user;

    socket.on('matchmaking:join', async (payload = {}, ack) => {
      try {
        const { category = null, difficulty = 'Easy', questionCount = 10 } = payload;
        if (!DIFFICULTIES.includes(difficulty)) {
          return ack?.({ error: 'Invalid difficulty' });
        }
        if (!QUESTION_COUNT_OPTIONS.includes(Number(questionCount))) {
          return ack?.({ error: 'Invalid question count' });
        }

        const blocked = await userModel.isBlocked(userId);
        if (blocked) {
          return ack?.({ error: 'Your account has been blocked' });
        }

        // Payment gate: matchmaking is entry-fee funded, so a user may only
        // join the queue if they have a verified (webhook- or verify-status
        // confirmed), not-yet-used Cashfree payment sitting ready. This
        // atomically claims one — nobody else can claim the same order.
        const payment = await paymentService.claimEntryForMatchmaking(userId);
        if (!payment) {
          return ack?.({ error: 'A verified payment is required before joining matchmaking', code: 'PAYMENT_REQUIRED' });
        }

        const criteria = { category, difficulty, questionCount: Number(questionCount) };
        const match = await matchmakingService.enqueue(criteria, {
          userId,
          username,
          socketId: socket.id,
          paymentId: payment.id,
        });

        if (match === 'ALREADY_QUEUED') {
          await paymentService.releaseUnusedEntry(payment.id);
          return ack?.({ error: 'You are already queued for a match' });
        }

        ack?.({ success: true, queued: true });

        if (match) {
          // Matched on category + difficulty + questionCount, both sides
          // already payment-verified. Don't create the room yet — both
          // players must explicitly accept first (see match:accept below).
          const pendingId = uuidv4();
          const acceptTimer = setTimeout(() => {
            cancelPendingMatch(pendingId, { notifyEvent: 'matchmaking:acceptTimeout' });
          }, MATCH_ACCEPT_TIMEOUT_MS);

          pendingMatches.set(pendingId, {
            playerA: match.playerA,
            playerB: match.playerB,
            criteria: match.criteria,
            accepted: new Set(),
            acceptTimer,
            roomCreating: false,
          });
          userPendingMatch.set(match.playerA.userId, pendingId);
          userPendingMatch.set(match.playerB.userId, pendingId);

          // Keep both claimed payments tracked as pending so a disconnect,
          // cancel, or accept-timeout between now and room creation still
          // hands them back instead of losing a paid entry.
          socketPendingPayment.set(match.playerA.socketId, match.playerA.paymentId);
          socketPendingPayment.set(match.playerB.socketId, match.playerB.paymentId);

          const matchedPayload = {
            pendingId,
            opponents: {
              [match.playerA.userId]: match.playerA.username,
              [match.playerB.userId]: match.playerB.username,
            },
            category: match.criteria.category,
            difficulty: match.criteria.difficulty,
            questionCount: match.criteria.questionCount,
            acceptTimeoutMs: MATCH_ACCEPT_TIMEOUT_MS,
          };
          io.to(match.playerA.socketId).emit('matchmaking:matched', matchedPayload);
          io.to(match.playerB.socketId).emit('matchmaking:matched', matchedPayload);
        } else {
          // Still waiting for an opponent — remember the claimed entry so
          // it can be handed back if this user cancels or disconnects
          // before a match forms.
          socketPendingPayment.set(socket.id, payment.id);
        }
      } catch (err) {
        logger.error('matchmaking:join error', { stack: err.stack, message: err.message, userId });
        ack?.({ error: 'Failed to join matchmaking' });
      }
    });

    // Both matched players must call this before a room is created. Once
    // both have accepted, this is the only place quizRoomService.createMatch
    // ever gets called for a given pendingId — the roomCreating flag is
    // flipped synchronously (no await beforehand) so a duplicate/racing
    // accept for the same pendingId can never trigger a second room.
    socket.on('match:accept', async ({ pendingId } = {}, ack) => {
      try {
        const pending = pendingMatches.get(pendingId);
        if (!pending) {
          return ack?.({ error: 'This match is no longer available' });
        }
        if (pending.playerA.userId !== userId && pending.playerB.userId !== userId) {
          return ack?.({ error: 'You are not part of this match' });
        }
        if (pending.roomCreating) {
          // Room creation already triggered by the other accept — treat a
          // repeat/racing accept as an idempotent no-op.
          return ack?.({ success: true, waitingForOpponent: false });
        }

        pending.accepted.add(userId);

        if (pending.accepted.size < 2) {
          ack?.({ success: true, waitingForOpponent: true });
          io.to(otherPlayer(pending, userId).socketId).emit('match:opponentAccepted');
          return;
        }

        // Both accepted. Flip the guard and remove the pending entry
        // synchronously, before any await — this is what makes duplicate
        // room creation impossible even under concurrent accept events.
        pending.roomCreating = true;
        clearTimeout(pending.acceptTimer);
        pendingMatches.delete(pendingId);
        userPendingMatch.delete(pending.playerA.userId);
        userPendingMatch.delete(pending.playerB.userId);

        ack?.({ success: true, waitingForOpponent: false });

        const matchId = await quizRoomService.createMatch(io, {
          playerA: pending.playerA,
          playerB: pending.playerB,
          criteria: pending.criteria,
        });

        socketPendingPayment.delete(pending.playerA.socketId);
        socketPendingPayment.delete(pending.playerB.socketId);

        if (matchId) {
          socketMatch.set(pending.playerA.socketId, matchId);
          socketMatch.set(pending.playerB.socketId, matchId);
        }
        // If matchId is null, quizRoomService already released both
        // payments and notified both sockets directly (insufficient
        // questions for this criteria).
      } catch (err) {
        logger.error('match:accept error', { stack: err.stack, message: err.message, userId });
        ack?.({ error: 'Failed to accept match' });
      }
    });

    socket.on('matchmaking:cancel', async (payload, ack) => {
      await matchmakingService.dequeue(userId);

      const pendingId = userPendingMatch.get(userId);
      if (pendingId) {
        await cancelPendingMatch(pendingId, { notifyEvent: 'matchmaking:opponentLeft' });
      }

      const pendingPaymentId = socketPendingPayment.get(socket.id);
      if (pendingPaymentId) {
        await paymentService.releaseUnusedEntry(pendingPaymentId);
        socketPendingPayment.delete(socket.id);
      }
      ack?.({ success: true });
    });

    socket.on('match:submitAnswer', async ({ matchId, questionIndex, chosenIndex }, ack) => {
      const result = await quizRoomService.submitAnswer(io, { matchId, userId, questionIndex, chosenIndex });
      socketMatch.set(socket.id, matchId);
      ack?.(result);
    });

    socket.on('disconnect', async () => {
      await matchmakingService.dequeue(userId);

      const pendingId = userPendingMatch.get(userId);
      if (pendingId) {
        await cancelPendingMatch(pendingId, { notifyEvent: 'matchmaking:opponentLeft' });
      }

      const pendingPaymentId = socketPendingPayment.get(socket.id);
      if (pendingPaymentId) {
        await paymentService.releaseUnusedEntry(pendingPaymentId);
        socketPendingPayment.delete(socket.id);
      }
      const matchId = socketMatch.get(socket.id);
      if (matchId) {
        await quizRoomService.handleDisconnect(io, matchId, userId);
        socketMatch.delete(socket.id);
      }
    });
  });
}

module.exports = initSockets;
