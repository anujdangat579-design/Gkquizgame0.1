// Simple in-memory matchmaking queue, keyed by "category:difficulty:questionCount".
// Good enough for a single Node instance; for horizontal scaling this would
// need to move to Redis, but that's out of scope here.

const queues = new Map(); // key -> array of { userId, username, socketId }

function queueKey({ category, difficulty, questionCount }) {
  return `${category || 'any'}:${difficulty}:${questionCount}`;
}

function enqueue(criteria, entry) {
  const key = queueKey(criteria);
  if (!queues.has(key)) queues.set(key, []);
  const queue = queues.get(key);

  // Avoid double-queueing the same user.
  const alreadyQueued = queue.find((e) => e.userId === entry.userId);
  if (alreadyQueued) return null;

  queue.push(entry);

  if (queue.length >= 2) {
    const [playerA, playerB] = queue.splice(0, 2);
    return { playerA, playerB, criteria };
  }
  return null;
}

function dequeue(userId) {
  for (const [key, queue] of queues.entries()) {
    const idx = queue.findIndex((e) => e.userId === userId);
    if (idx !== -1) {
      queue.splice(idx, 1);
      return true;
    }
  }
  return false;
}

module.exports = { enqueue, dequeue, queueKey };
