jest.mock('../src/config/redis');
jest.mock('../src/models/auditLogModel');
jest.mock('../src/models/paymentModel');
// Keep verifyWebhookSignature real (pure crypto, no network) — only stub the
// two calls that would otherwise hit the real Cashfree API.
jest.mock('../src/services/cashfreeService', () => {
  const actual = jest.requireActual('../src/services/cashfreeService');
  return {
    ...actual,
    createOrder: jest.fn(),
    fetchOrder: jest.fn(),
  };
});

const crypto = require('crypto');
const request = require('supertest');
const paymentModel = require('../src/models/paymentModel');
const cashfreeService = require('../src/services/cashfreeService');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const rival = { id: '22222222-2222-2222-2222-222222222222', username: 'playerTwo', role: 'player' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

beforeEach(() => {
  jest.clearAllMocks();
});

describe('POST /api/payments/orders', () => {
  it('requires authentication', async () => {
    const res = await request(app).post('/api/payments/orders').send({});
    expect(res.status).toBe(401);
    expect(cashfreeService.createOrder).not.toHaveBeenCalled();
  });

  it('creates a Cashfree order and a CREATED payment row', async () => {
    cashfreeService.createOrder.mockResolvedValue({
      cfOrderId: 'order_abc',
      orderStatus: 'ACTIVE',
      paymentSessionId: 'session_xyz',
    });
    paymentModel.create.mockResolvedValue({
      id: 'pay-1',
      user_id: player.id,
      cf_order_id: 'order_abc',
      status: 'CREATED',
    });

    const res = await request(app)
      .post('/api/payments/orders')
      .set('Authorization', bearer(player))
      .send({ difficulty: 'Easy', questionCount: 10 });

    expect(res.status).toBe(201);
    expect(res.body.order).toMatchObject({
      paymentId: 'pay-1',
      cfOrderId: 'order_abc',
      paymentSessionId: 'session_xyz',
      amount: 10,
      currency: 'INR',
    });

    // The amount charged always comes from server config, never the request body.
    expect(cashfreeService.createOrder).toHaveBeenCalledWith(
      expect.objectContaining({ amount: 10, currency: 'INR' })
    );
    expect(paymentModel.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: player.id, orderAmount: 10, currency: 'INR' })
    );
  });

  it('rejects an invalid difficulty', async () => {
    const res = await request(app)
      .post('/api/payments/orders')
      .set('Authorization', bearer(player))
      .send({ difficulty: 'Impossible' });

    expect(res.status).toBe(400);
    expect(cashfreeService.createOrder).not.toHaveBeenCalled();
  });

  it('propagates a Cashfree failure as a 502', async () => {
    const err = new Error('Failed to create payment order');
    err.status = 502;
    cashfreeService.createOrder.mockRejectedValue(err);

    const res = await request(app)
      .post('/api/payments/orders')
      .set('Authorization', bearer(player))
      .send({});

    expect(res.status).toBe(502);
    expect(paymentModel.create).not.toHaveBeenCalled();
  });
});

describe('GET /api/payments/orders/:orderId/verify', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/payments/orders/order_abc/verify');
    expect(res.status).toBe(401);
  });

  it('returns 404 for an order that does not exist', async () => {
    paymentModel.findByOrderId.mockResolvedValue(null);

    const res = await request(app)
      .get('/api/payments/orders/order_missing/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(404);
  });

  it("returns 404 for another user's order", async () => {
    paymentModel.findByOrderId.mockResolvedValue({ id: 'pay-1', user_id: rival.id, status: 'CREATED' });

    const res = await request(app)
      .get('/api/payments/orders/order_abc/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(404);
    expect(cashfreeService.fetchOrder).not.toHaveBeenCalled();
  });

  it('short-circuits to PAID without calling Cashfree if already PAID locally', async () => {
    paymentModel.findByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id, status: 'PAID' });

    const res = await request(app)
      .get('/api/payments/orders/order_abc/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'PAID', paymentId: 'pay-1' });
    expect(cashfreeService.fetchOrder).not.toHaveBeenCalled();
  });

  it('marks the order PAID when Cashfree confirms it', async () => {
    paymentModel.findByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id, status: 'CREATED' });
    cashfreeService.fetchOrder.mockResolvedValue({ cfOrderId: 'order_abc', orderStatus: 'PAID' });
    paymentModel.markPaidByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id });

    const res = await request(app)
      .get('/api/payments/orders/order_abc/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'PAID', paymentId: 'pay-1' });
    expect(paymentModel.markPaidByOrderId).toHaveBeenCalledWith('order_abc', {});
  });

  it('reports PENDING while Cashfree still shows the order as active', async () => {
    paymentModel.findByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id, status: 'CREATED' });
    cashfreeService.fetchOrder.mockResolvedValue({ cfOrderId: 'order_abc', orderStatus: 'ACTIVE' });

    const res = await request(app)
      .get('/api/payments/orders/order_abc/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'PENDING', paymentId: 'pay-1' });
    expect(paymentModel.markFailedByOrderId).not.toHaveBeenCalled();
  });

  it('marks the order FAILED when Cashfree reports it expired', async () => {
    paymentModel.findByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id, status: 'CREATED' });
    cashfreeService.fetchOrder.mockResolvedValue({ cfOrderId: 'order_abc', orderStatus: 'EXPIRED' });

    const res = await request(app)
      .get('/api/payments/orders/order_abc/verify')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'FAILED', paymentId: 'pay-1' });
    expect(paymentModel.markFailedByOrderId).toHaveBeenCalledWith('order_abc');
  });
});

describe('POST /api/payments/webhook', () => {
  function signedRequest(payload) {
    const rawBody = JSON.stringify(payload);
    const timestamp = String(Date.now());
    const signature = crypto
      .createHmac('sha256', process.env.CASHFREE_WEBHOOK_SECRET)
      .update(timestamp + rawBody)
      .digest('base64');

    return request(app)
      .post('/api/payments/webhook')
      .set('x-webhook-signature', signature)
      .set('x-webhook-timestamp', timestamp)
      .set('Content-Type', 'application/json')
      .send(rawBody);
  }

  it('rejects a request with no signature header', async () => {
    const res = await request(app)
      .post('/api/payments/webhook')
      .send({ type: 'PAYMENT_SUCCESS_WEBHOOK', data: { order: { order_id: 'order_abc' } } });

    expect(res.status).toBe(401);
    expect(paymentModel.markPaidByOrderId).not.toHaveBeenCalled();
  });

  it('rejects a request with a tampered signature', async () => {
    const res = await request(app)
      .post('/api/payments/webhook')
      .set('x-webhook-signature', 'not-a-real-signature')
      .set('x-webhook-timestamp', String(Date.now()))
      .send({ type: 'PAYMENT_SUCCESS_WEBHOOK', data: { order: { order_id: 'order_abc' } } });

    expect(res.status).toBe(401);
    expect(paymentModel.markPaidByOrderId).not.toHaveBeenCalled();
  });

  it('marks the order PAID on a validly signed PAYMENT_SUCCESS_WEBHOOK', async () => {
    paymentModel.markPaidByOrderId.mockResolvedValue({ id: 'pay-1', user_id: player.id });

    const res = await signedRequest({
      type: 'PAYMENT_SUCCESS_WEBHOOK',
      data: {
        order: { order_id: 'order_abc' },
        payment: { payment_status: 'SUCCESS', cf_payment_id: 987654 },
      },
    });

    expect(res.status).toBe(200);
    expect(paymentModel.markPaidByOrderId).toHaveBeenCalledWith('order_abc', { cfPaymentId: '987654' });
  });

  it('marks the order FAILED on a validly signed failure webhook', async () => {
    paymentModel.markFailedByOrderId.mockResolvedValue({ id: 'pay-1' });

    const res = await signedRequest({
      type: 'PAYMENT_FAILED_WEBHOOK',
      data: { order: { order_id: 'order_abc' }, payment: { payment_status: 'FAILED' } },
    });

    expect(res.status).toBe(200);
    expect(paymentModel.markFailedByOrderId).toHaveBeenCalledWith('order_abc');
  });

  it('is a no-op (but still 200s) for a signed payload with no order_id', async () => {
    const res = await signedRequest({ type: 'PAYMENT_SUCCESS_WEBHOOK', data: {} });

    expect(res.status).toBe(200);
    expect(paymentModel.markPaidByOrderId).not.toHaveBeenCalled();
  });

  it('is idempotent — a redelivered webhook for an already-PAID order no-ops', async () => {
    // markPaidByOrderId only transitions CREATED -> PAID; simulate the
    // second delivery finding it already PAID by resolving null.
    paymentModel.markPaidByOrderId.mockResolvedValue(null);

    const res = await signedRequest({
      type: 'PAYMENT_SUCCESS_WEBHOOK',
      data: { order: { order_id: 'order_abc' }, payment: { payment_status: 'SUCCESS' } },
    });

    expect(res.status).toBe(200);
    expect(paymentModel.markPaidByOrderId).toHaveBeenCalledTimes(1);
  });
});
