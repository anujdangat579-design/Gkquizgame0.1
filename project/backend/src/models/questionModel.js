const db = require('../database/connection');

async function list({ category, difficulty, limit, offset }) {
  const conditions = [];
  const params = [];

  if (category) {
    params.push(category);
    conditions.push(`category = $${params.length}`);
  }
  if (difficulty) {
    params.push(difficulty);
    conditions.push(`difficulty = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  params.push(limit, offset);

  const result = await db.query(
    `SELECT * FROM questions ${where} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return result.rows;
}

async function create({ id, category, difficulty, questionText, options, correctIndex, explanation, createdBy }) {
  const result = await db.query(
    `INSERT INTO questions (id, category, difficulty, question_text, options, correct_index, explanation, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [id, category, difficulty, questionText, JSON.stringify(options), correctIndex, explanation || null, createdBy]
  );
  return result.rows[0];
}

async function update(id, { questionText, options, correctIndex, explanation, isActive }) {
  const result = await db.query(
    `UPDATE questions SET
       question_text = COALESCE($1, question_text),
       options = COALESCE($2, options),
       correct_index = COALESCE($3, correct_index),
       explanation = COALESCE($4, explanation),
       is_active = COALESCE($5, is_active)
     WHERE id = $6
     RETURNING *`,
    [
      questionText || null,
      options ? JSON.stringify(options) : null,
      Number.isInteger(correctIndex) ? correctIndex : null,
      explanation !== undefined ? explanation : null,
      typeof isActive === 'boolean' ? isActive : null,
      id,
    ]
  );
  return result.rows[0] || null;
}

async function remove(id) {
  await db.query('DELETE FROM questions WHERE id = $1', [id]);
}

// Fetches the full question rows (options, correct_index, explanation, etc.)
// for a known list of ids, preserving no particular order — callers that
// care about the original match order (e.g. the score-report builder)
// re-sort using match.question_ids themselves.
async function findByIds(ids) {
  if (!ids || ids.length === 0) return [];
  const result = await db.query('SELECT * FROM questions WHERE id = ANY($1::uuid[])', [ids]);
  return result.rows;
}

// Used by the matchmaking/quiz-room flow to build a match's question set.
async function pickRandomForMatch({ category, difficulty, questionCount }) {
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

module.exports = { list, create, update, remove, pickRandomForMatch, findByIds };
