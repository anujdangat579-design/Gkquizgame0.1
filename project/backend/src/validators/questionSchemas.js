const { z } = require('zod');
const { DIFFICULTIES } = require('../constants');

const difficultySchema = z.enum(DIFFICULTIES, {
  errorMap: () => ({ message: `difficulty must be one of: ${DIFFICULTIES.join(', ')}` }),
});

// Shared shape for a single question, used both standalone (create) and
// nested inside an array (bulk create). correctIndex is additionally
// cross-checked against options.length via superRefine below.
const questionShape = {
  category: z.string().trim().min(1, 'category is required'),
  difficulty: difficultySchema,
  questionText: z.string().trim().min(3, 'questionText is required'),
  options: z
    .array(z.string().trim().min(1, 'each option must be a non-empty string'))
    .min(2, 'options must be an array of at least 2 choices'),
  correctIndex: z.number().int().min(0, 'correctIndex must be a non-negative integer'),
  explanation: z.string().trim().optional(),
};

function withCorrectIndexCheck(schema) {
  return schema.superRefine((data, ctx) => {
    if (data.options && data.correctIndex >= data.options.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['correctIndex'],
        message: 'correctIndex must be a valid index into options',
      });
    }
  });
}

const createQuestionSchema = withCorrectIndexCheck(z.object(questionShape));

const bulkCreateQuestionSchema = z.object({
  questions: z
    .array(withCorrectIndexCheck(z.object(questionShape)))
    .min(1, 'questions must be a non-empty array'),
});

// Partial update — every field optional, but well-formed if present, and at
// least one field must actually be supplied.
const updateQuestionSchema = z
  .object({
    category: questionShape.category.optional(),
    difficulty: difficultySchema.optional(),
    questionText: questionShape.questionText.optional(),
    options: questionShape.options.optional(),
    correctIndex: questionShape.correctIndex.optional(),
    explanation: questionShape.explanation,
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  })
  .superRefine((data, ctx) => {
    if (data.options && data.correctIndex !== undefined && data.correctIndex >= data.options.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['correctIndex'],
        message: 'correctIndex must be a valid index into options',
      });
    }
  });

// Query params for GET /api/questions — page/pageSize are coerced from the
// query string to numbers; the service layer still clamps pageSize to a
// sane max (200), so this only rejects genuinely malformed input.
const listQuestionsQuerySchema = z.object({
  category: z.string().trim().min(1).optional(),
  difficulty: difficultySchema.optional(),
  page: z.coerce.number().int('page must be an integer').positive('page must be a positive integer').optional(),
  pageSize: z.coerce
    .number()
    .int('pageSize must be an integer')
    .positive('pageSize must be a positive integer')
    .optional(),
});

module.exports = {
  createQuestionSchema,
  bulkCreateQuestionSchema,
  updateQuestionSchema,
  listQuestionsQuerySchema,
};
