const { z } = require('zod');

const uuidSchema = z.string().uuid('Must be a valid UUID');

// Shared pagination/sorting used by both the plain list and the search
// endpoint, since search is really "list with a required q".
const paginationFields = {
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sortBy: z.enum(['created_at', 'username', 'status']).default('created_at'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
};

const listUsersQuerySchema = z.object({
  ...paginationFields,
  role: z.enum(['player', 'admin']).optional(),
  status: z.enum(['active', 'blocked', 'suspended']).optional(),
  q: z.string().trim().min(1).max(200).optional(),
});

const searchUsersQuerySchema = z.object({
  ...paginationFields,
  role: z.enum(['player', 'admin']).optional(),
  status: z.enum(['active', 'blocked', 'suspended']).optional(),
  q: z.string().trim().min(1, 'q is required').max(200),
});

const userIdParamSchema = z.object({
  id: uuidSchema,
});

const blockUserBodySchema = z.object({
  reason: z.string().trim().min(1).max(500).optional(),
});

const unblockUserBodySchema = z.object({
  reason: z.string().trim().min(1).max(500).optional(),
});

// Suspend needs exactly one of a relative duration or an absolute end date.
const suspendUserBodySchema = z
  .object({
    reason: z.string().trim().min(1).max(500).optional(),
    days: z.coerce.number().int().min(1).max(365).optional(),
    until: z.string().datetime({ offset: true }).optional(),
  })
  .refine((data) => (data.days ? 1 : 0) + (data.until ? 1 : 0) === 1, {
    message: 'Provide exactly one of "days" or "until"',
  })
  .refine((data) => !data.until || new Date(data.until).getTime() > Date.now(), {
    message: '"until" must be in the future',
    path: ['until'],
  });

module.exports = {
  listUsersQuerySchema,
  searchUsersQuerySchema,
  userIdParamSchema,
  blockUserBodySchema,
  unblockUserBodySchema,
  suspendUserBodySchema,
};
