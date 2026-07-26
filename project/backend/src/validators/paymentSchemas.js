const { z } = require('zod');
const { DIFFICULTIES, QUESTION_COUNT_OPTIONS } = require('../constants');

// The criteria are optional — they're only stored on the order so the
// client can be told what queue to join once it's paid; the actual entry
// fee amount is always the server-configured flat fee, never taken from
// the client.
const createOrderSchema = z.object({
  category: z.string().min(1).max(64).optional().nullable(),
  difficulty: z.enum(DIFFICULTIES).optional(),
  questionCount: z.coerce.number().refine((v) => QUESTION_COUNT_OPTIONS.includes(v), {
    message: `questionCount must be one of ${QUESTION_COUNT_OPTIONS.join(', ')}`,
  }).optional(),
});

const orderIdParamSchema = z.object({
  orderId: z.string().min(1).max(64),
});

module.exports = { createOrderSchema, orderIdParamSchema };
