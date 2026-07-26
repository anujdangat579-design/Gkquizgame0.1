jest.mock('../src/config/redis');
jest.mock('../src/database/connection');

const request = require('supertest');
const redis = require('../src/config/redis');
const db = require('../src/database/connection');
const app = require('../src/app');

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /health', () => {
  it('returns 200 with database: ok and redis: ok when both are reachable', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }], rowCount: 1 });

    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      status: 'ok',
      environment: 'test',
      database: 'ok',
      redis: 'ok',
    });
    expect(typeof res.body.uptimeSeconds).toBe('number');
    expect(typeof res.body.timestamp).toBe('string');
  });

  it('still returns 200 with redis: unreachable when Redis ping fails', async () => {
    redis.ping.mockRejectedValueOnce(new Error('ECONNREFUSED'));
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.database).toBe('ok');
    expect(res.body.redis).toBe('unreachable');
  });

  it('still returns 200 with database: unreachable when the DB query fails', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockRejectedValueOnce(new Error('Connection terminated'));

    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.database).toBe('unreachable');
    expect(res.body.redis).toBe('ok');
  });

  it('does not require authentication', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

    const res = await request(app).get('/health');

    expect(res.status).not.toBe(401);
  });
});

describe('GET /ready', () => {
  it('returns 200 and status ok when both dependencies are reachable', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

    const res = await request(app).get('/ready');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'ok', database: 'ok', redis: 'ok' });
  });

  it('returns 503 when the database is unreachable', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockRejectedValueOnce(new Error('Connection terminated'));

    const res = await request(app).get('/ready');

    expect(res.status).toBe(503);
    expect(res.body).toMatchObject({ status: 'unavailable', database: 'unreachable', redis: 'ok' });
  });

  it('returns 503 when Redis is unreachable', async () => {
    redis.ping.mockRejectedValueOnce(new Error('ECONNREFUSED'));
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

    const res = await request(app).get('/ready');

    expect(res.status).toBe(503);
    expect(res.body).toMatchObject({ status: 'unavailable', database: 'ok', redis: 'unreachable' });
  });

  it('returns 503 when both are unreachable', async () => {
    redis.ping.mockRejectedValueOnce(new Error('ECONNREFUSED'));
    db.query.mockRejectedValueOnce(new Error('Connection terminated'));

    const res = await request(app).get('/ready');

    expect(res.status).toBe(503);
    expect(res.body.status).toBe('unavailable');
  });

  it('does not require authentication', async () => {
    redis.ping.mockResolvedValueOnce('PONG');
    db.query.mockResolvedValueOnce({ rows: [], rowCount: 1 });

    const res = await request(app).get('/ready');

    expect(res.status).not.toBe(401);
  });
});

describe('GET /live', () => {
  it('returns 200 with status ok without touching the database or Redis', async () => {
    const res = await request(app).get('/live');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(typeof res.body.uptimeSeconds).toBe('number');
    expect(typeof res.body.timestamp).toBe('string');
    expect(db.query).not.toHaveBeenCalled();
    expect(redis.ping).not.toHaveBeenCalled();
  });

  it('does not require authentication', async () => {
    const res = await request(app).get('/live');
    expect(res.status).not.toBe(401);
  });
});

describe('unknown routes', () => {
  it('returns a consistent 404 JSON body', async () => {
    const res = await request(app).get('/this-route-does-not-exist');

    expect(res.status).toBe(404);
    expect(res.body).toHaveProperty('error');
    expect(res.body.error).toMatch(/Route not found/);
  });
});
