const swaggerJSDoc = require('swagger-jsdoc');
const env = require('./env');

// --- OpenAPI definition ----------------------------------------------------
// Static metadata + reusable components (schemas, security scheme, common
// error responses). The actual path documentation lives next to each route
// as JSDoc `@openapi` blocks in src/routes/*.js — swagger-jsdoc scans those
// files (see `apis` below) and merges them into this definition.
const definition = {
  openapi: '3.0.3',
  info: {
    title: 'GK Quiz Backend API',
    version: '1.0.0',
    description:
      'REST API for a 1v1 General Knowledge quiz app with a Cashfree-backed entry fee. ' +
      'Real-time match play itself happens over Socket.IO, not documented here — this covers the HTTP surface: ' +
      'authentication, question bank management, quiz/leaderboard history, and payments. ' +
      'A player must hold a verified, unspent paid entry (see /api/payments) before matchmaking:join will queue them.',
  },
  servers: [
    {
      url: `http://localhost:${env.port}`,
      description: 'Local development',
    },
  ],
  tags: [
    { name: 'Auth', description: 'Registration, login, token refresh, and session/profile info' },
    { name: 'Questions', description: 'Question bank CRUD (admin-only writes)' },
    { name: 'Quiz', description: 'Leaderboard and match history' },
    { name: 'Payments', description: 'Cashfree order creation, status verification, and webhook' },
    { name: 'Audit', description: 'Admin, auth, payment, and score audit trail (admin-only reads)' },
    { name: 'Health', description: 'Service health check' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Access token returned from /api/auth/register, /api/auth/login, or /api/auth/refresh.',
      },
    },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          error: { type: 'string', example: 'Invalid username or password' },
          details: {
            type: 'array',
            items: { type: 'object' },
            description: 'Present on validation failures — one entry per failed field (from Zod).',
          },
        },
      },
      User: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          username: { type: 'string', example: 'quizmaster99' },
          email: { type: 'string', format: 'email', nullable: true, example: 'player@example.com' },
          phone: { type: 'string', nullable: true, example: '+14155552671' },
          name: { type: 'string', nullable: true, example: 'Jordan' },
          avatar_url: { type: 'string', nullable: true, example: 'https://lh3.googleusercontent.com/a/...' },
          role: { type: 'string', enum: ['player', 'admin'], example: 'player' },
          auth_provider: { type: 'string', enum: ['password', 'otp', 'google'], example: 'otp' },
        },
      },
      OtpRequestRequest: {
        type: 'object',
        required: ['phone'],
        properties: {
          phone: { type: 'string', description: 'E.164 format', example: '+14155552671' },
        },
      },
      OtpVerifyRequest: {
        type: 'object',
        required: ['phone', 'otp'],
        properties: {
          phone: { type: 'string', description: 'E.164 format', example: '+14155552671' },
          otp: { type: 'string', pattern: '^\\d{6}$', example: '042917' },
        },
      },
      GoogleLoginRequest: {
        type: 'object',
        required: ['idToken'],
        properties: {
          idToken: { type: 'string', description: 'Google Sign-In ID token from the client SDK' },
        },
      },
      UpdateProfileRequest: {
        type: 'object',
        description: 'At least one field is required.',
        properties: {
          name: { type: 'string', minLength: 1, maxLength: 100, example: 'Jordan' },
          avatarUrl: { type: 'string', format: 'uri' },
          email: { type: 'string', format: 'email' },
        },
      },
      AuthTokens: {
        type: 'object',
        properties: {
          accessToken: { type: 'string', description: 'Short-lived JWT (default 15m). Send as `Authorization: Bearer <token>`.' },
          refreshToken: { type: 'string', description: 'Long-lived JWT (default 30d). Used only against /api/auth/refresh.' },
        },
      },
      RegisterRequest: {
        type: 'object',
        required: ['username', 'email', 'password'],
        properties: {
          username: { type: 'string', minLength: 3, maxLength: 32, pattern: '^[a-zA-Z0-9_]+$', example: 'quizmaster99' },
          email: { type: 'string', format: 'email', example: 'player@example.com' },
          password: { type: 'string', minLength: 8, maxLength: 128, example: 'SuperSecret123' },
        },
      },
      LoginRequest: {
        type: 'object',
        required: ['username', 'password'],
        properties: {
          username: { type: 'string', description: 'Username or email', example: 'quizmaster99' },
          password: { type: 'string', example: 'SuperSecret123' },
        },
      },
      RefreshRequest: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string' },
        },
      },
      AuthResponse: {
        allOf: [
          { type: 'object', properties: { user: { $ref: '#/components/schemas/User' } } },
          { $ref: '#/components/schemas/AuthTokens' },
        ],
      },
      Question: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          category: { type: 'string', example: 'Geography' },
          difficulty: { type: 'string', enum: ['Easy', 'Medium', 'Hard'] },
          question_text: { type: 'string', example: 'What is the capital of France?' },
          options: { type: 'array', items: { type: 'string' }, example: ['Paris', 'Lyon', 'Marseille', 'Nice'] },
          correct_index: { type: 'integer', example: 0 },
          explanation: { type: 'string', nullable: true },
          created_by: { type: 'string', format: 'uuid' },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
      QuestionInput: {
        type: 'object',
        required: ['category', 'difficulty', 'questionText', 'options', 'correctIndex'],
        properties: {
          category: { type: 'string', example: 'Geography' },
          difficulty: { type: 'string', enum: ['Easy', 'Medium', 'Hard'] },
          questionText: { type: 'string', minLength: 3, example: 'What is the capital of France?' },
          options: {
            type: 'array',
            minItems: 2,
            items: { type: 'string' },
            example: ['Paris', 'Lyon', 'Marseille', 'Nice'],
          },
          correctIndex: { type: 'integer', minimum: 0, example: 0 },
          explanation: { type: 'string', nullable: true },
        },
      },
      BulkQuestionInput: {
        type: 'object',
        required: ['questions'],
        properties: {
          questions: {
            type: 'array',
            minItems: 1,
            items: { $ref: '#/components/schemas/QuestionInput' },
          },
        },
      },
      Match: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          player_a_id: { type: 'string', format: 'uuid' },
          player_b_id: { type: 'string', format: 'uuid' },
          status: { type: 'string', enum: ['in_progress', 'completed', 'abandoned'] },
          winner_id: { type: 'string', format: 'uuid', nullable: true },
          created_at: { type: 'string', format: 'date-time' },
          completed_at: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      MatchAnswer: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          match_id: { type: 'string', format: 'uuid' },
          user_id: { type: 'string', format: 'uuid' },
          question_id: { type: 'string', format: 'uuid' },
          selected_index: { type: 'integer', nullable: true },
          is_correct: { type: 'boolean' },
          answered_at: { type: 'string', format: 'date-time' },
        },
      },
      LeaderboardEntry: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          username: { type: 'string' },
          matches_played: { type: 'integer' },
          matches_won: { type: 'integer' },
          total_correct: { type: 'integer' },
          total_answered: { type: 'integer' },
        },
      },
      AuditLog: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          category: { type: 'string', enum: ['auth', 'admin', 'payment', 'score'] },
          action: { type: 'string', example: 'QUESTION_DELETED' },
          status: { type: 'string', enum: ['success', 'failure'] },
          actor_id: { type: 'string', format: 'uuid', nullable: true },
          actor_username: { type: 'string', nullable: true },
          entity_type: { type: 'string', nullable: true, example: 'question' },
          entity_id: { type: 'string', format: 'uuid', nullable: true },
          ip_address: { type: 'string', nullable: true },
          user_agent: { type: 'string', nullable: true },
          metadata: { type: 'object', nullable: true },
          created_at: { type: 'string', format: 'date-time' },
        },
      },
    },

    responses: {
      BadRequest: {
        description: 'Validation error',
        content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
      },
      Unauthorized: {
        description: 'Missing, malformed, invalid, or expired access token',
        content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
      },
      Forbidden: {
        description: 'Authenticated but not allowed to perform this action',
        content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
      },
      NotFound: {
        description: 'Resource not found',
        content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
      },
    },
  },
};

const options = {
  definition,
  // Scan route files for `@openapi` JSDoc blocks.
  apis: ['./src/routes/*.js', './src/app.js'],
};

module.exports = swaggerJSDoc(options);
