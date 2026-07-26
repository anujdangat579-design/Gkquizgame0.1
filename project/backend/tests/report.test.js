jest.mock('../src/config/redis');
jest.mock('../src/services/cacheService');
jest.mock('../src/models/matchModel');
jest.mock('../src/models/matchAnswerModel');
jest.mock('../src/models/questionModel');
jest.mock('../src/models/userModel');

const request = require('supertest');
const matchModel = require('../src/models/matchModel');
const matchAnswerModel = require('../src/models/matchAnswerModel');
const questionModel = require('../src/models/questionModel');
const userModel = require('../src/models/userModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const rival = { id: '22222222-2222-2222-2222-222222222222', username: 'playerTwo', role: 'player' };
const stranger = { id: '33333333-3333-3333-3333-333333333333', username: 'stranger', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

const matchId = '66666666-6666-6666-6666-666666666666';
const q1 = 'aaaaaaaa-0000-0000-0000-000000000001';
const q2 = 'aaaaaaaa-0000-0000-0000-000000000002';

const match = {
  id: matchId,
  player_a_id: player.id,
  player_b_id: rival.id,
  category: 'Science',
  difficulty: 'Medium',
  question_count: 2,
  question_ids: [q1, q2],
  status: 'completed',
  winner_id: player.id,
  score_a: 2,
  score_b: 1,
  started_at: '2026-07-24T10:00:00.000Z',
  completed_at: '2026-07-24T10:05:00.000Z',
};

const questions = [
  {
    id: q1,
    category: 'Science',
    difficulty: 'Medium',
    question_text: 'What is H2O commonly known as?',
    options: ['Salt', 'Water', 'Oxygen', 'Hydrogen'],
    correct_index: 1,
    explanation: 'H2O is the chemical formula for water.',
  },
  {
    id: q2,
    category: 'Science',
    difficulty: 'Medium',
    question_text: 'How many legs does a spider have?',
    options: ['6', '8', '10', '12'],
    correct_index: 1,
    explanation: 'Spiders are arachnids and have eight legs.',
  },
];

const answers = [
  { match_id: matchId, user_id: player.id, question_id: q1, chosen_index: 1, is_correct: true, answer_ms: 3000 },
  { match_id: matchId, user_id: player.id, question_id: q2, chosen_index: 1, is_correct: true, answer_ms: 4000 },
  { match_id: matchId, user_id: rival.id, question_id: q1, chosen_index: 0, is_correct: false, answer_ms: 5000 },
  { match_id: matchId, user_id: rival.id, question_id: q2, chosen_index: 1, is_correct: true, answer_ms: 2000 },
];

beforeEach(() => {
  jest.clearAllMocks();
  matchModel.findById.mockResolvedValue(match);
  matchAnswerModel.findByMatchId.mockResolvedValue(answers);
  questionModel.findByIds.mockResolvedValue(questions);
  userModel.findPublicById.mockImplementation(async (id) => {
    if (id === player.id) return { id: player.id, username: 'playerOne', name: 'Player One' };
    if (id === rival.id) return { id: rival.id, username: 'playerTwo', name: 'Player Two' };
    return null;
  });
});

describe('GET /api/quiz/matches/:id/report', () => {
  it('requires authentication', async () => {
    const res = await request(app).get(`/api/quiz/matches/${matchId}/report`);
    expect(res.status).toBe(401);
  });

  it('rejects a non-UUID id with 400 before hitting the model', async () => {
    const res = await request(app)
      .get('/api/quiz/matches/not-a-uuid/report')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(matchModel.findById).not.toHaveBeenCalled();
  });

  it('returns 404 when the match does not exist', async () => {
    matchModel.findById.mockResolvedValue(null);

    const res = await request(app)
      .get(`/api/quiz/matches/${matchId}/report`)
      .set('Authorization', bearer(player));

    expect(res.status).toBe(404);
  });

  it('returns 403 for an authenticated user who is not a participant', async () => {
    const res = await request(app)
      .get(`/api/quiz/matches/${matchId}/report`)
      .set('Authorization', bearer(stranger));

    expect(res.status).toBe(403);
    expect(matchAnswerModel.findByMatchId).not.toHaveBeenCalled();
  });

  it('allows an admin to view a report for a match they are not part of', async () => {
    const res = await request(app)
      .get(`/api/quiz/matches/${matchId}/report`)
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
  });

  it('builds correct per-player stats, results, and question review for a participant', async () => {
    const res = await request(app)
      .get(`/api/quiz/matches/${matchId}/report`)
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    const { report } = res.body;

    // Match summary
    expect(report.match.id).toBe(matchId);
    expect(report.match.durationSeconds).toBe(300);
    expect(report.match.margin).toBe(1);

    // Player A (playerOne) went 2/2, player B (playerTwo) went 1/2
    expect(report.players.playerA.score).toBe(2);
    expect(report.players.playerA.accuracyPct).toBe(100);
    expect(report.players.playerA.result).toBe('won');
    expect(report.players.playerA.avgAnswerMs).toBe(3500);

    expect(report.players.playerB.score).toBe(1);
    expect(report.players.playerB.accuracyPct).toBe(50);
    expect(report.players.playerB.result).toBe('lost');

    // Question review includes explanations and both players' chosen answers
    expect(report.questions).toHaveLength(2);
    expect(report.questions[0].correctAnswerText).toBe('Water');
    expect(report.questions[0].explanation).toBe('H2O is the chemical formula for water.');
    expect(report.questions[0].playerA.isCorrect).toBe(true);
    expect(report.questions[0].playerB.isCorrect).toBe(false);
    expect(report.questions[0].playerB.chosenText).toBe('Salt');

    // On Q2 both got it right, but rival (playerB) answered faster
    expect(report.questions[1].fasterCorrectPlayer).toBe(rival.id);
    expect(report.headToHead.fasterCorrectAnswers[rival.id]).toBe(1);
    expect(report.headToHead.fasterCorrectAnswers[player.id]).toBe(1);
  });

  it('handles unanswered questions (e.g. an abandoned match) without crashing', async () => {
    matchAnswerModel.findByMatchId.mockResolvedValue([answers[0], answers[2]]); // only Q1 answered by both

    const res = await request(app)
      .get(`/api/quiz/matches/${matchId}/report`)
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    const { report } = res.body;
    expect(report.players.playerA.unanswered).toBe(1);
    expect(report.questions[1].playerA.answered).toBe(false);
    expect(report.questions[1].fasterCorrectPlayer).toBeNull();
  });
});
