jest.mock('../src/config/redis');
jest.mock('../src/models/userModel');

const request = require('supertest');
const userModel = require('../src/models/userModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };
const otherAdmin = { id: '55555555-5555-5555-5555-555555555555', username: 'adminTwo', role: 'admin' };

const sampleUser = {
  id: player.id,
  username: 'playerOne',
  email: 'player1@example.com',
  phone: '+14155550000',
  name: 'Player One',
  avatar_url: null,
  role: 'player',
  auth_provider: 'password',
  status: 'active',
  suspended_until: null,
  status_reason: null,
  status_changed_by: null,
  status_changed_at: null,
  created_at: '2026-01-01T00:00:00.000Z',
};

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /api/admin/users', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/admin/users');
    expect(res.status).toBe(401);
  });

  it('rejects a non-admin user with 403', async () => {
    const res = await request(app).get('/api/admin/users').set('Authorization', bearer(player));
    expect(res.status).toBe(403);
  });

  it('returns a paginated list for an admin', async () => {
    userModel.findUsers.mockResolvedValue({ rows: [sampleUser], total: 1 });

    const res = await request(app).get('/api/admin/users').set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body.users).toHaveLength(1);
    expect(res.body.pagination).toEqual({ page: 1, limit: 20, total: 1, totalPages: 1 });
    expect(userModel.findUsers).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 20, sortBy: 'created_at', sortOrder: 'desc' })
    );
  });

  it('rejects an out-of-range limit', async () => {
    const res = await request(app)
      .get('/api/admin/users?limit=500')
      .set('Authorization', bearer(admin));
    expect(res.status).toBe(400);
    expect(userModel.findUsers).not.toHaveBeenCalled();
  });
});

describe('GET /api/admin/users/search', () => {
  it('requires q', async () => {
    const res = await request(app).get('/api/admin/users/search').set('Authorization', bearer(admin));
    expect(res.status).toBe(400);
  });

  it('searches by free text', async () => {
    userModel.findUsers.mockResolvedValue({ rows: [sampleUser], total: 1 });

    const res = await request(app)
      .get('/api/admin/users/search?q=player')
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(userModel.findUsers).toHaveBeenCalledWith(expect.objectContaining({ q: 'player' }));
  });
});

describe('GET /api/admin/users/:id', () => {
  it('returns 404 when the user does not exist', async () => {
    userModel.findById.mockResolvedValue(null);

    const res = await request(app)
      .get(`/api/admin/users/${player.id}`)
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(404);
  });

  it('returns the user', async () => {
    userModel.findById.mockResolvedValue(sampleUser);

    const res = await request(app)
      .get(`/api/admin/users/${player.id}`)
      .set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body.username).toBe('playerOne');
  });

  it('rejects a non-uuid id', async () => {
    const res = await request(app).get('/api/admin/users/not-a-uuid').set('Authorization', bearer(admin));
    expect(res.status).toBe(400);
  });
});

describe('POST /api/admin/users/:id/block', () => {
  it('blocks a player and revokes sessions', async () => {
    userModel.findRoleById.mockResolvedValue({ id: player.id, role: 'player' });
    userModel.updateStatus.mockResolvedValue({ ...sampleUser, status: 'blocked' });

    const res = await request(app)
      .post(`/api/admin/users/${player.id}/block`)
      .set('Authorization', bearer(admin))
      .send({ reason: 'Fraudulent payments' });

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('blocked');
    expect(userModel.updateStatus).toHaveBeenCalledWith(
      player.id,
      expect.objectContaining({ status: 'blocked', reason: 'Fraudulent payments', changedBy: admin.id })
    );
    expect(userModel.revokeActiveSessions).toHaveBeenCalledWith(player.id);
  });

  it('refuses to block another admin', async () => {
    userModel.findRoleById.mockResolvedValue({ id: otherAdmin.id, role: 'admin' });

    const res = await request(app)
      .post(`/api/admin/users/${otherAdmin.id}/block`)
      .set('Authorization', bearer(admin))
      .send({});

    expect(res.status).toBe(403);
    expect(userModel.updateStatus).not.toHaveBeenCalled();
  });

  it('refuses to block yourself', async () => {
    const res = await request(app)
      .post(`/api/admin/users/${admin.id}/block`)
      .set('Authorization', bearer(admin))
      .send({});

    expect(res.status).toBe(400);
    expect(userModel.findRoleById).not.toHaveBeenCalled();
  });
});

describe('POST /api/admin/users/:id/unblock', () => {
  it('restores status to active', async () => {
    userModel.findRoleById.mockResolvedValue({ id: player.id, role: 'player' });
    userModel.updateStatus.mockResolvedValue({ ...sampleUser, status: 'active' });

    const res = await request(app)
      .post(`/api/admin/users/${player.id}/unblock`)
      .set('Authorization', bearer(admin))
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('active');
    expect(userModel.updateStatus).toHaveBeenCalledWith(
      player.id,
      expect.objectContaining({ status: 'active', suspendedUntil: null })
    );
  });
});

describe('POST /api/admin/users/:id/suspend', () => {
  it('suspends for a relative number of days', async () => {
    userModel.findRoleById.mockResolvedValue({ id: player.id, role: 'player' });
    userModel.updateStatus.mockResolvedValue({ ...sampleUser, status: 'suspended' });

    const res = await request(app)
      .post(`/api/admin/users/${player.id}/suspend`)
      .set('Authorization', bearer(admin))
      .send({ days: 7, reason: 'Abuse report' });

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('suspended');
    expect(userModel.revokeActiveSessions).toHaveBeenCalledWith(player.id);
  });

  it('rejects both days and until being provided', async () => {
    const res = await request(app)
      .post(`/api/admin/users/${player.id}/suspend`)
      .set('Authorization', bearer(admin))
      .send({ days: 7, until: '2026-08-01T00:00:00Z' });

    expect(res.status).toBe(400);
    expect(userModel.updateStatus).not.toHaveBeenCalled();
  });

  it('rejects neither days nor until being provided', async () => {
    const res = await request(app)
      .post(`/api/admin/users/${player.id}/suspend`)
      .set('Authorization', bearer(admin))
      .send({ reason: 'no duration given' });

    expect(res.status).toBe(400);
  });

  it('rejects an "until" in the past', async () => {
    const res = await request(app)
      .post(`/api/admin/users/${player.id}/suspend`)
      .set('Authorization', bearer(admin))
      .send({ until: '2020-01-01T00:00:00Z' });

    expect(res.status).toBe(400);
  });
});
