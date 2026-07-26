jest.mock('../src/config/redis');
jest.mock('../src/services/cacheService');
jest.mock('../src/models/questionModel');

const request = require('supertest');
const questionModel = require('../src/models/questionModel');
const { signAccessToken } = require('../src/utils/jwt');
const app = require('../src/app');

const player = { id: '11111111-1111-1111-1111-111111111111', username: 'playerOne', role: 'player' };
const admin = { id: '44444444-4444-4444-4444-444444444444', username: 'adminUser', role: 'admin' };

function bearer(user) {
  return `Bearer ${signAccessToken(user)}`;
}

const validQuestion = {
  category: 'Geography',
  difficulty: 'Easy',
  questionText: 'What is the capital of France?',
  options: ['Paris', 'London', 'Berlin'],
  correctIndex: 0,
};

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /api/questions', () => {
  it('requires authentication', async () => {
    const res = await request(app).get('/api/questions');
    expect(res.status).toBe(401);
  });

  it('rejects an invalid difficulty with 400 before hitting the model', async () => {
    const res = await request(app)
      .get('/api/questions?difficulty=Impossible')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
    expect(questionModel.list).not.toHaveBeenCalled();
  });

  it('rejects a non-numeric page with 400', async () => {
    const res = await request(app).get('/api/questions?page=abc').set('Authorization', bearer(player));

    expect(res.status).toBe(400);
    expect(questionModel.list).not.toHaveBeenCalled();
  });

  it('lists questions with default paging when no query params are given', async () => {
    questionModel.list.mockResolvedValue([]);

    const res = await request(app).get('/api/questions').set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(questionModel.list).toHaveBeenCalledWith(
      expect.objectContaining({ limit: 50, offset: 0 })
    );
  });

  it('passes through a valid category/difficulty/page filter', async () => {
    questionModel.list.mockResolvedValue([]);

    const res = await request(app)
      .get('/api/questions?category=Geography&difficulty=Hard&page=2&pageSize=10')
      .set('Authorization', bearer(player));

    expect(res.status).toBe(200);
    expect(questionModel.list).toHaveBeenCalledWith(
      expect.objectContaining({ category: 'Geography', difficulty: 'Hard', limit: 10, offset: 10 })
    );
  });
});

describe('POST /api/questions', () => {
  it('requires authentication', async () => {
    const res = await request(app).post('/api/questions').send(validQuestion);
    expect(res.status).toBe(401);
  });

  it('requires admin role', async () => {
    const res = await request(app)
      .post('/api/questions')
      .set('Authorization', bearer(player))
      .send(validQuestion);

    expect(res.status).toBe(403);
    expect(questionModel.create).not.toHaveBeenCalled();
  });

  it('rejects a missing questionText with 400', async () => {
    const { questionText, ...rest } = validQuestion;
    const res = await request(app).post('/api/questions').set('Authorization', bearer(admin)).send(rest);

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
    expect(questionModel.create).not.toHaveBeenCalled();
  });

  it('rejects an invalid difficulty with 400', async () => {
    const res = await request(app)
      .post('/api/questions')
      .set('Authorization', bearer(admin))
      .send({ ...validQuestion, difficulty: 'Impossible' });

    expect(res.status).toBe(400);
  });

  it('rejects fewer than 2 options with 400', async () => {
    const res = await request(app)
      .post('/api/questions')
      .set('Authorization', bearer(admin))
      .send({ ...validQuestion, options: ['Only one'] });

    expect(res.status).toBe(400);
  });

  it('rejects a correctIndex that is out of range for options with 400', async () => {
    const res = await request(app)
      .post('/api/questions')
      .set('Authorization', bearer(admin))
      .send({ ...validQuestion, correctIndex: 99 });

    expect(res.status).toBe(400);
    expect(questionModel.create).not.toHaveBeenCalled();
  });

  it('creates a question given a fully valid payload', async () => {
    questionModel.create.mockResolvedValue({ id: 'q1', ...validQuestion });

    const res = await request(app)
      .post('/api/questions')
      .set('Authorization', bearer(admin))
      .send(validQuestion);

    expect(res.status).toBe(201);
    expect(res.body.question).toMatchObject({ id: 'q1' });
    expect(questionModel.create).toHaveBeenCalledTimes(1);
  });
});

describe('POST /api/questions/bulk', () => {
  it('rejects an empty questions array with 400', async () => {
    const res = await request(app)
      .post('/api/questions/bulk')
      .set('Authorization', bearer(admin))
      .send({ questions: [] });

    expect(res.status).toBe(400);
    expect(questionModel.create).not.toHaveBeenCalled();
  });

  it('rejects the whole batch with 400 when any single entry is malformed', async () => {
    const res = await request(app)
      .post('/api/questions/bulk')
      .set('Authorization', bearer(admin))
      .send({ questions: [validQuestion, { ...validQuestion, options: ['only one'] }] });

    expect(res.status).toBe(400);
    expect(questionModel.create).not.toHaveBeenCalled();
  });

  it('creates every question when the whole batch is well-formed', async () => {
    questionModel.create
      .mockResolvedValueOnce({ id: 'q1' })
      .mockResolvedValueOnce({ id: 'q2' });

    const res = await request(app)
      .post('/api/questions/bulk')
      .set('Authorization', bearer(admin))
      .send({ questions: [validQuestion, validQuestion] });

    expect(res.status).toBe(201);
    expect(res.body.insertedCount).toBe(2);
    expect(questionModel.create).toHaveBeenCalledTimes(2);
  });
});

describe('PATCH /api/questions/:id', () => {
  const id = '66666666-6666-6666-6666-666666666666';

  it('rejects a non-UUID id with 400 before hitting the model', async () => {
    const res = await request(app)
      .patch('/api/questions/not-a-uuid')
      .set('Authorization', bearer(admin))
      .send({ category: 'History' });

    expect(res.status).toBe(400);
    expect(questionModel.update).not.toHaveBeenCalled();
  });

  it('rejects an empty update body with 400', async () => {
    const res = await request(app).patch(`/api/questions/${id}`).set('Authorization', bearer(admin)).send({});

    expect(res.status).toBe(400);
    expect(questionModel.update).not.toHaveBeenCalled();
  });

  it('rejects a correctIndex that no longer fits the supplied options with 400', async () => {
    const res = await request(app)
      .patch(`/api/questions/${id}`)
      .set('Authorization', bearer(admin))
      .send({ options: ['A', 'B'], correctIndex: 5 });

    expect(res.status).toBe(400);
    expect(questionModel.update).not.toHaveBeenCalled();
  });

  it('updates the question given a valid partial payload', async () => {
    questionModel.update.mockResolvedValue({ id, category: 'History' });

    const res = await request(app)
      .patch(`/api/questions/${id}`)
      .set('Authorization', bearer(admin))
      .send({ category: 'History' });

    expect(res.status).toBe(200);
    expect(res.body.question).toMatchObject({ id, category: 'History' });
  });
});

describe('DELETE /api/questions/:id', () => {
  it('rejects a non-UUID id with 400 before hitting the model', async () => {
    const res = await request(app).delete('/api/questions/not-a-uuid').set('Authorization', bearer(admin));

    expect(res.status).toBe(400);
    expect(questionModel.remove).not.toHaveBeenCalled();
  });

  it('deletes a question given a valid id', async () => {
    const id = '66666666-6666-6666-6666-666666666666';
    questionModel.remove.mockResolvedValue(undefined);

    const res = await request(app).delete(`/api/questions/${id}`).set('Authorization', bearer(admin));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true });
  });
});
