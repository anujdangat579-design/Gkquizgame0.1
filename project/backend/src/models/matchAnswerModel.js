const db = require('../database/connection');

async function create({ id, matchId, userId, questionId, chosenIndex, isCorrect, answerMs }) {
  await db.query(
    `INSERT INTO match_answers (id, match_id, user_id, question_id, chosen_index, is_correct, answer_ms)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [id, matchId, userId, questionId, chosenIndex, isCorrect, answerMs]
  );
}

async function findByMatchId(matchId) {
  const result = await db.query(
    `SELECT ma.*, q.question_text, q.category
     FROM match_answers ma
     JOIN questions q ON q.id = ma.question_id
     WHERE ma.match_id = $1
     ORDER BY ma.answered_at ASC`,
    [matchId]
  );
  return result.rows;
}

module.exports = { create, findByMatchId };
