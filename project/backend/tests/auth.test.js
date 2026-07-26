jest.mock('../src/config/redis');
jest.mock('../src/models/userModel');
jest.mock('../src/models/refreshTokenModel');
jest.mock('../src/models/leaderboardModel');

const request = require('supertest');
const userModel = require('../src/models/userModel');
const refreshTokenModel = require('../src/models/refreshTokenModel');
const leaderboardModel = require('../src/models/leaderboardModel');
const app = require('../src/app');

// In-memory stand-ins for the `users` / `refresh_tokens` tables, wired up to
// the mocked models below so a full register -> login -> refresh -> logout
// flow behaves like it would against a real database, without touching one.
let users;
let refreshTokens;

function seedUsers() {
  users = new Map();
  refreshTokens = new Map();

  userModel.existsByUsernameOrEmail.mockImplementation(async (username, email) =>
    [...users.values()].some((u) => u.username === username || u.email === email)
  );

  userModel.create.mockImplementation(async ({ id, username, email, passwordHash }) => {
    users.set(id, { id, username, email, password_hash: passwordHash, role: 'player', is_blocked: false });
    return { id, username, email, role: 'player' };
  });

  userModel.findAuthByIdentifier.mockImplementation(async (identifier) => {
    const u = [...users.values()].find((row) => row.username === identifier || row.email === identifier);
    return u || null;
  });

  userModel.findAuthById.mockImplementation(async (id) => {
    const u = users.get(id);
    if (!u) return null;
    const { password_hash, ...rest } = u;
    return rest;
  });

  userModel.findPublicById.mockImplementation(async (id) => {
    const u = users.get(id);
    if (!u) return null;
    return { id: u.id, username: u.username, email: u.email, role: u.role, created_at: new Date().toISOString() };
  });

  refreshTokenModel.create.mockImplementation(async ({ id, userId, tokenHash, expiresAt }) => {
    refreshTokens.set(id, { id, userId, tokenHash, expiresAt, revoked: false });
  });

  refreshTokenModel.findByUserAndHash.mockImplementation(async (userId, tokenHash) => {
    const rec = [...refreshTokens.values()].find((t) => t.userId === userId && t.tokenHash === tokenHash);
    return rec ? { id: rec.id, revoked: rec.revoked, expires_at: rec.expiresAt } : null;
  });

  refreshTokenModel.revokeById.mockImplementation(async (id) => {
    const rec = refreshTokens.get(id);
    if (rec) rec.revoked = true;
  });

  refreshTokenModel.revokeByHash.mockImplementation(async (tokenHash) => {
    for (const rec of refreshTokens.values()) {
      if (rec.tokenHash === tokenHash) rec.revoked = true;
    }
  });

  leaderboardModel.initForUser.mockResolvedValue(undefined);
}

beforeEach(() => {
  jest.clearAllMocks();
  seedUsers();
});

const validRegistration = {
  username: 'quizmaster99',
  email: 'player@example.com',
  password: 'SuperSecret123',
};

describe('POST /api/auth/register', () => {
  it('creates a new account and returns a user + token pair', async () => {
    const res = await request(app).post('/api/auth/register').send(validRegistration);

    expect(res.status).toBe(201);
    expect(res.body.user).toMatchObject({
      username: validRegistration.username,
      email: validRegistration.email,
      role: 'player',
    });
    expect(res.body.user).not.toHaveProperty('password');
    expect(res.body.user).not.toHaveProperty('passwordHash');
    expect(typeof res.body.accessToken).toBe('string');
    expect(typeof res.body.refreshToken).toBe('string');
    expect(leaderboardModel.initForUser).toHaveBeenCalledWith(res.body.user.id);
  });

  it('rejects a weak password with 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ ...validRegistration, password: 'short' });

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('rejects an invalid username with 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ ...validRegistration, username: 'a b!' });

    expect(res.status).toBe(400);
  });

  it('rejects a duplicate username/email with 409', async () => {
    const first = await request(app).post('/api/auth/register').send(validRegistration);
    expect(first.status).toBe(201);

    const second = await request(app)
      .post('/api/auth/register')
      .send({ ...validRegistration, email: 'someoneelse@example.com' });

    expect(second.status).toBe(409);
  });
});

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await request(app).post('/api/auth/register').send(validRegistration);
  });

  it('logs in with a correct username + password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: validRegistration.username, password: validRegistration.password });

    expect(res.status).toBe(200);
    expect(res.body.user.username).toBe(validRegistration.username);
    expect(typeof res.body.accessToken).toBe('string');
  });

  it('logs in using the email as the identifier', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: validRegistration.email, password: validRegistration.password });

    expect(res.status).toBe(200);
  });

  it('rejects an incorrect password with 401', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: validRegistration.username, password: 'WrongPassword1' });

    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  it('rejects an unknown username with 401', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'nobody-here', password: 'WhoKnows123' });

    expect(res.status).toBe(401);
  });
});

describe('GET /api/auth/me', () => {
  it('rejects a request with no Authorization header', async () => {
    const res = await request(app).get('/api/auth/me');

    expect(res.status).toBe(401);
  });

  it('rejects a malformed/garbage token', async () => {
    const res = await request(app).get('/api/auth/me').set('Authorization', 'Bearer not-a-real-token');

    expect(res.status).toBe(401);
  });

  it('returns the current user profile for a valid access token', async () => {
    const registerRes = await request(app).post('/api/auth/register').send(validRegistration);
    const { accessToken } = registerRes.body;

    const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({
      id: registerRes.body.user.id,
      username: validRegistration.username,
      email: validRegistration.email,
    });
  });
});

describe('POST /api/auth/refresh', () => {
  it('issues a new token pair and rotates (invalidates) the old refresh token', async () => {
    const registerRes = await request(app).post('/api/auth/register').send(validRegistration);
    const { refreshToken } = registerRes.body;

    const refreshRes = await request(app).post('/api/auth/refresh').send({ refreshToken });

    expect(refreshRes.status).toBe(200);
    expect(typeof refreshRes.body.accessToken).toBe('string');
    expect(typeof refreshRes.body.refreshToken).toBe('string');
    expect(refreshRes.body.refreshToken).not.toBe(refreshToken);

    // The original (now-rotated) refresh token must no longer work.
    const reuseRes = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(reuseRes.status).toBe(401);
  });

  it('rejects a missing refreshToken with 400', async () => {
    const res = await request(app).post('/api/auth/refresh').send({});

    expect(res.status).toBe(400);
  });

  it('rejects a malformed refresh token with 401', async () => {
    const res = await request(app).post('/api/auth/refresh').send({ refreshToken: 'garbage.token.value' });

    expect(res.status).toBe(401);
  });
});

describe('POST /api/auth/logout', () => {
  it('revokes the refresh token so it can no longer be used to refresh', async () => {
    const registerRes = await request(app).post('/api/auth/register').send(validRegistration);
    const { refreshToken } = registerRes.body;

    const logoutRes = await request(app).post('/api/auth/logout').send({ refreshToken });
    expect(logoutRes.status).toBe(200);
    expect(logoutRes.body).toEqual({ success: true });

    const refreshAfterLogout = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(refreshAfterLogout.status).toBe(401);
  });

  it('succeeds even with no refreshToken (best-effort logout)', async () => {
    const res = await request(app).post('/api/auth/logout').send({});

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true });
  });

  it('rejects a non-string refreshToken with 400', async () => {
    const res = await request(app).post('/api/auth/logout').send({ refreshToken: 12345 });

    expect(res.status).toBe(400);
  });
});
