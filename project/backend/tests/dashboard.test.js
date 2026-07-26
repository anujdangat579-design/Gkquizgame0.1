jest.mock('../src/config/redis');
jest.mock('../src/services/cacheService');
jest.mock('../src/models/dashboardModel');

const request = require('supertest');
const dashboardModel = require('../src/models/dashboardModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

beforeEach(() => {
  jest.clearAllMocks();
  dashboardModel.getStats.mockResolvedValue({
    total_users: '1520',
    active_users: '84',
    total_matches: '3980',
    live_matches: '6',
    total_payments: '2210',
    paid_payments: '2001',
    total_revenue: '100050.00',
  });
});

describe('GET /api/admin/dashboard', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/admin/dashboard');
    expect(res.status).toBe(401);
    expect(dashboardModel.getStats).not.toHaveBeenCalled();
  });

  it('rejects a non-admin user with 403', async () => {
    const res = await request(app).get('/api/admin/dashboard').set('Authorization', bearer(player));
    expect(res.status).toBe(403);
    expect(dashboardModel.getStats).not.toHaveBeenCalled();
  });

  it('returns the dashboard summary for an admin, coerced to numbers', async () => {
    const res = await request(app).get('/api/admin/dashboard').set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      totalUsers: 1520,
      activeUsers: 84,
      totalMatches: 3980,
      liveMatches: 6,
      totalPayments: 2210,
      paidPayments: 2001,
      totalRevenue: 100050,
    });
    expect(dashboardModel.getStats).toHaveBeenCalledTimes(1);
  });
});
