const { z } = require('zod');

const CATEGORIES = ['auth', 'admin', 'payment', 'score'];
const STATUSES = ['success', 'failure'];

// Query params for GET /api/audit-logs. Every filter is optional and
// combined with AND; page/pageSize are coerced from the query string the
// same way listQuestionsQuerySchema does. The service layer still clamps
// pageSize to a sane max (200).
const listAuditLogsQuerySchema = z.object({
  category: z.enum(CATEGORIES, {
    errorMap: () => ({ message: `category must be one of: ${CATEGORIES.join(', ')}` }),
  }).optional(),
  action: z.string().trim().min(1).optional(),
  status: z.enum(STATUSES, {
    errorMap: () => ({ message: `status must be one of: ${STATUSES.join(', ')}` }),
  }).optional(),
  actorId: z.string().uuid('actorId must be a valid UUID').optional(),
  entityType: z.string().trim().min(1).optional(),
  entityId: z.string().uuid('entityId must be a valid UUID').optional(),
  from: z.coerce.date({ errorMap: () => ({ message: 'from must be a valid date/time' }) }).optional(),
  to: z.coerce.date({ errorMap: () => ({ message: 'to must be a valid date/time' }) }).optional(),
  page: z.coerce.number().int('page must be an integer').positive('page must be a positive integer').optional(),
  pageSize: z.coerce
    .number()
    .int('pageSize must be an integer')
    .positive('pageSize must be a positive integer')
    .optional(),
});

module.exports = { listAuditLogsQuerySchema, CATEGORIES, STATUSES };
