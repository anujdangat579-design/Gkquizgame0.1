jest.mock('../src/config/redis');
jest.mock('../src/services/cacheService');
jest.mock('../src/models/leaderboardModel');
jest.mock('../src/models/matchModel');
jest.mock('../src/models/matchAnswerModel');

const request = require('supertest');
const leaderboardModel = require('../src/models/leaderboardModel');
const matchModel = require('../src/models/matchModel');
const matchAnswerModel = require('../src/models/matchAnswerModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const rival = { id: '22222222-2222-2222-2222-222222222222', username: 'playerTwo', role: 'player' };
const stranger = { id: '33333333-3333-3333-3333-333333333333', username: 'stranger', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /api/quiz/leaderboard', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/quiz/leaderboard');

    expect(res.status).toBe(401);
    expect(leaderboardModel.getTop).not.toHaveBeenCalled();
  });

  it('returns the leaderboard, defaulting the limit to 50', async () => {
    const rows = [
      { id: player.id, username: player.username, matches_played: 10, matches_won: 7, total_correct: 60, total_answered: 80 },
    ];
    leaderboardModel.getTop.mockResolvedValue(rows);

    const res = await request(app).get('/api/quiz/leaderboard').set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ leaderboard: rows });
    expect(leaderboardModel.getTop).toHaveBeenCalledWith(50);
  });

  it('honors a valid ?limit and caps it at 200', async () => {
    leaderboardModel.getTop.mockResolvedValue([]);

    await request(app).get('/api/quiz/leaderboard?limit=10').set('Authorization', bearer(player));
    expect(leaderboardModel.getTop).toHaveBeenLastCalledWith(10);

    await request(app).get('/api/quiz/leaderboard?limit=9999').set('Authorization', bearer(player));
    expect(leaderboardModel.getTop).toHaveBeenLastCalledWith(200);
  });

  it('rejects a non-numeric ?limit with 400', async () => {
    const res = await request(app)
      .get('/api/quiz/leaderboard?limit=abc')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(leaderboardModel.getTop).not.toHaveBeenCalled();
  });
});

  it('rejects an invalid ?period with 400', async () => {
    const res = await request(app)
      .get('/api/quiz/leaderboard?period=yearly')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(leaderboardModel.getTop).not.toHaveBeenCalled();
  });

  it('?period=daily ranks by score then accuracy, computed live from matches', async () => {
    const periodRows = [
      { id: player.id, username: player.username, matches_played: '3', matches_won: '2', score: '9', total_answered: '10', accuracy_pct: '90.0' },
      { id: rival.id, username: rival.username, matches_played: '2', matches_won: '0', score: '5', total_answered: '10', accuracy_pct: '50.0' },
    ];
    leaderboardModel.getTopByPeriod.mockResolvedValue(periodRows);

    const res = await request(app)
      .get('/api/quiz/leaderboard?period=daily')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(leaderboardModel.getTop).not.toHaveBeenCalled();
    expect(leaderboardModel.getTopByPeriod).toHaveBeenCalledTimes(1);
    const callArg = leaderboardModel.getTopByPeriod.mock.calls[0][0];
    expect(callArg.limit).toBe(50);
    expect(callArg.start).toBeInstanceOf(Date);

    expect(res.body.leaderboard).toEqual([
      { id: player.id, username: player.username, matchesPlayed: 3, matchesWon: 2, score: 9, totalAnswered: 10, accuracyPct: 90 },
      { id: rival.id, username: rival.username, matchesPlayed: 2, matchesWon: 0, score: 5, totalAnswered: 10, accuracyPct: 50 },
    ]);
  });

  it('?period=weekly and ?period=monthly both route through getTopByPeriod', async () => {
    leaderboardModel.getTopByPeriod.mockResolvedValue([]);

    await request(app).get('/api/quiz/leaderboard?period=weekly').set('Authorization', bearer(player));
    await request(app).get('/api/quiz/leaderboard?period=monthly').set('Authorization', bearer(player));

    expect(leaderboardModel.getTopByPeriod).toHaveBeenCalledTimes(2);
  });

  it('?period=all_time reshapes the same rollup rows with accuracyPct added', async () => {
    const rows = [
      { id: player.id, username: player.username, matches_played: 10, matches_won: 7, total_correct: 60, total_answered: 80 },
    ];
    leaderboardModel.getTop.mockResolvedValue(rows);

    const res = await request(app)
      .get('/api/quiz/leaderboard?period=all_time')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(leaderboardModel.getTopByPeriod).not.toHaveBeenCalled();
    expect(res.body.leaderboard).toEqual([
      { id: player.id, username: player.username, matchesPlayed: 10, matchesWon: 7, score: 60, totalAnswered: 80, accuracyPct: 75 },
    ]);
  });
});

describe('GET /api/quiz/matches/mine', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/quiz/matches/mine');

    expect(res.status).toBe(401);
  });

  it("returns the authenticated user's match history", async () => {
    const matches = [
      {
        id: '55555555-5555-5555-5555-555555555555',
        player_a_id: player.id,
        player_b_id: rival.id,
        status: 'completed',
        winner_id: player.id,
      },
    ];
    matchModel.findMineByUser.mockResolvedValue(matches);

    const res = await request(app).get('/api/quiz/matches/mine').set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ matches });
    expect(matchModel.findMineByUser).toHaveBeenCalledWith(player.id);
  });
});

describe('GET /api/quiz/matches/:id', () => {
  const matchId = '66666666-6666-6666-6666-666666666666';
  const match = {
    id: matchId,
    player_a_id: player.id,
    player_b_id: rival.id,
    status: 'completed',
    winner_id: player.id,
  };
  const answers = [
    { id: 'a1', match_id: matchId, user_id: player.id, question_id: 'q1', is_correct: true },
  ];

  it('requires authentication', async () => {
    const res = await request(app).get(`/api/quiz/matches/${matchId}`);

    expect(res.status).toBe(401);
  });

  it('rejects a non-UUID id with 400 before hitting the model', async () => {
    const res = await request(app).get('/api/quiz/matches/not-a-uuid').set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(matchModel.findById).not.toHaveBeenCalled();
  });

  it('returns 404 when the match does not exist', async () => {
    matchModel.findById.mockResolvedValue(null);

    const res = await request(app).get(`/api/quiz/matches/${matchId}`).set('Authorization', bearer(player));

    expect(res.status).toBe(404);
  });

  it('returns 403 for an authenticated user who is not a participant', async () => {
    matchModel.findById.mockResolvedValue(match);

    const res = await request(app).get(`/api/quiz/matches/${matchId}`).set('Authorization', bearer(stranger));

    expect(res.status).toBe(403);
    expect(matchAnswerModel.findByMatchId).not.toHaveBeenCalled();
  });

  it('returns match + answers to a participant', async () => {
    matchModel.findById.mockResolvedValue(match);
    matchAnswerModel.findByMatchId.mockResolvedValue(answers);

    const res = await request(app).get(`/api/quiz/matches/${matchId}`).set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ match, answers });
  });

  it('allows an admin to view a match they are not part of', async () => {
    matchModel.findById.mockResolvedValue(match);
    matchAnswerModel.findByMatchId.mockResolvedValue(answers);

    const res = await request(app).get(`/api/quiz/matches/${matchId}`).set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ match, answers });
  });
});
