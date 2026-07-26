const { z } = require('zod');

// Validates a `:id` route param as a UUID (all primary keys in this schema
// are UUIDs — see migrations/001_init.sql). Rejects malformed ids with a 400
// before they ever reach a DB query.
const idParamSchema = z.object({
  id: z.string().uuid('id must be a valid UUID'),
});

module.exports = { idParamSchema };
