const db = require('../database/connection');

async function create({ id, playerAId, playerBId, category, difficulty, questionCount, questionIds }) {
  await db.query(
    `INSERT INTO matches (id, player_a_id, player_b_id, category, difficulty, question_count, question_ids, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'in_progress')`,
    [id, playerAId, playerBId, category || null, difficulty, questionCount, JSON.stringify(questionIds)]
  );
}

async function markCompleted({ id, winnerId, scoreA, scoreB }) {
  await db.query(
    `UPDATE matches SET status = 'completed', winner_id = $1, score_a = $2, score_b = $3, completed_at = now()
     WHERE id = $4`,
    [winnerId, scoreA, scoreB, id]
  );
}

async function markAbandoned({ id, winnerId }) {
  await db.query(
    `UPDATE matches SET status = 'abandoned', winner_id = $1, completed_at = now() WHERE id = $2`,
    [winnerId || null, id]
  );
}

async function findById(id) {
  const result = await db.query('SELECT * FROM matches WHERE id = $1', [id]);
  return result.rows[0] || null;
}

async function findMineByUser(userId) {
  const result = await db.query(
    `SELECT id, category, difficulty, question_count, status, winner_id,
            score_a, score_b, player_a_id, player_b_id, started_at, completed_at
     FROM matches
     WHERE player_a_id = $1 OR player_b_id = $1
     ORDER BY started_at DESC
     LIMIT 50`,
    [userId]
  );
  return result.rows;
}

module.exports = { create, markCompleted, markAbandoned, findById, findMineByUser };
