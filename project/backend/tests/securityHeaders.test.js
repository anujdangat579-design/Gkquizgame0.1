jest.mock('../src/config/redis');
jest.mock('../src/database/connection');

const request = require('supertest');
const app = require('../src/app');

describe('security headers', () => {
  it('sets a strict CSP, Referrer-Policy, and Permissions-Policy on JSON API responses', async () => {
    const res = await request(app).get('/health');

    expect(res.headers['content-security-policy']).toContain("default-src 'none'");
    expect(res.headers['referrer-policy']).toBe('no-referrer');
    expect(res.headers['permissions-policy']).toContain('camera=()');
    expect(res.headers['permissions-policy']).toContain('microphone=()');
    expect(res.headers['permissions-policy']).toContain('geolocation=()');
    expect(res.headers['x-xss-protection']).toBe('0');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('applies the same hardened headers to 404s and error responses too', async () => {
    const res = await request(app).get('/no-such-route');

    expect(res.status).toBe(404);
    expect(res.headers['content-security-policy']).toContain("default-src 'none'");
    expect(res.headers['permissions-policy']).toContain('camera=()');
  });

  it('serves Swagger UI at /api-docs with a relaxed, self-scoped CSP (not the strict API default)', async () => {
    const res = await request(app).get('/api-docs/');

    expect(res.status).toBe(200);
    expect(res.headers['content-security-policy']).toContain("default-src 'self'");
    expect(res.headers['content-security-policy']).not.toContain("default-src 'none'");
  });

  it('keeps the strict CSP on /api-docs.json (the raw spec, not the HTML UI)', async () => {
    const res = await request(app).get('/api-docs.json');

    expect(res.status).toBe(200);
    expect(res.headers['content-security-policy']).toContain("default-src 'none'");
  });
});
