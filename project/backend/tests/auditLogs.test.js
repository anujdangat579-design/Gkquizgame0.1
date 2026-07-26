jest.mock('../src/config/redis');
jest.mock('../src/services/cacheService');
jest.mock('../src/models/questionModel');
jest.mock('../src/models/userModel');
jest.mock('../src/models/refreshTokenModel');
jest.mock('../src/models/leaderboardModel');
jest.mock('../src/models/auditLogModel');

const request = require('supertest');
const questionModel = require('../src/models/questionModel');
const userModel = require('../src/models/userModel');
const refreshTokenModel = require('../src/models/refreshTokenModel');
const auditLogModel = require('../src/models/auditLogModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

beforeEach(() => {
  jest.clearAllMocks();
  auditLogModel.insert.mockImplementation(async (entry) => ({ id: 'log-id', created_at: new Date().toISOString(), ...entry }));
  auditLogModel.list.mockResolvedValue({ rows: [], total: 0 });
});

describe('GET /api/audit-logs', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/audit-logs');
    expect(res.status).toBe(401);
  });

  it('rejects a non-admin user with 403', async () => {
    const res = await request(app).get('/api/audit-logs').set('Authorization', bearer(player));
    expect(res.status).toBe(403);
    expect(auditLogModel.list).not.toHaveBeenCalled();
  });

  it('rejects an invalid category with 400 before hitting the model', async () => {
    const res = await request(app)
      .get('/api/audit-logs?category=bogus')
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(400);
    expect(auditLogModel.list).not.toHaveBeenCalled();
  });

  it('lists audit logs for an admin with default paging', async () => {
    const res = await request(app).get('/api/audit-logs').set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ logs: [], total: 0, page: 1, pageSize: 50 });
    expect(auditLogModel.list).toHaveBeenCalledWith(
      expect.objectContaining({ limit: 50, offset: 0 })
    );
  });

  it('passes through category/action/status/page filters', async () => {
    const res = await request(app)
      .get('/api/audit-logs?category=admin&action=QUESTION_DELETED&status=success&page=2&pageSize=10')
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(auditLogModel.list).toHaveBeenCalledWith(
      expect.objectContaining({
        category: 'admin',
        action: 'QUESTION_DELETED',
        status: 'success',
        limit: 10,
        offset: 10,
      })
    );
  });
});

describe('audit trail from login attempts', () => {
  beforeEach(() => {
    userModel.findAuthByIdentifier.mockResolvedValue(null);
  });

  it('records a failure with reason user_not_found for an unknown identifier', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'ghost', password: 'whatever123' });

    expect(res.status).toBe(401);
    expect(auditLogModel.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        category: 'auth',
        action: 'LOGIN_FAILURE',
        status: 'failure',
        metadata: { reason: 'user_not_found' },
      })
    );
  });

  it('records a failure with reason account_blocked for a blocked account', async () => {
    userModel.findAuthByIdentifier.mockResolvedValue({
      id: player.id,
      username: player.username,
      password_hash: 'irrelevant',
      role: 'player',
      is_blocked: true,
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: player.username, password: 'whatever123' });

    expect(res.status).toBe(403);
    expect(auditLogModel.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        category: 'auth',
        action: 'LOGIN_FAILURE',
        status: 'failure',
        actorId: player.id,
        metadata: { reason: 'account_blocked' },
      })
    );
  });

  it('records a success entry once tokens are issued', async () => {
    const bcrypt = require('bcryptjs');
    const passwordHash = await bcrypt.hash('correcthorse123', 4);

    userModel.findAuthByIdentifier.mockResolvedValue({
      id: player.id,
      username: player.username,
      password_hash: passwordHash,
      role: 'player',
      is_blocked: false,
    });
    refreshTokenModel.create.mockResolvedValue(undefined);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: player.username, password: 'correcthorse123' });

    expect(res.status).toBe(200);
    expect(auditLogModel.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        category: 'auth',
        action: 'LOGIN_SUCCESS',
        status: 'success',
        actorId: player.id,
      })
    );
  });
});

describe('audit trail from admin question actions', () => {
  it('logs QUESTION_DELETED with the acting admin', async () => {
    questionModel.remove.mockResolvedValue(undefined);

    const res = await request(app)
      .delete('/api/questions/22222222-2222-2222-2222-222222222222')
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(auditLogModel.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        category: 'admin',
        action: 'QUESTION_DELETED',
        actorId: admin.id,
        actorUsername: admin.username,
        entityType: 'question',
        entityId: '22222222-2222-2222-2222-222222222222',
      })
    );
  });

  it('does not log anything for a non-admin, since the request is rejected first', async () => {
    const res = await request(app)
      .delete('/api/questions/22222222-2222-2222-2222-222222222222')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(403);
    expect(auditLogModel.insert).not.toHaveBeenCalled();
  });
});
