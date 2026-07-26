const { ZodError } = require('zod');

// Formats a ZodError into the same { error, details } shape the API has
// always returned for validation failures, so existing clients/tests that
// check res.body.error keep working unchanged.
function formatZodError(err) {
  const details = err.errors.map((issue) => ({
    field: issue.path.join('.') || '(root)',
    msg: issue.message,
  }));
  return { error: details[0]?.msg || 'Validation failed', details };
}

/**
 * Builds an Express middleware that validates req.params / req.query / req.body
 * against the given Zod schemas, in that order, short-circuiting with a 400
 * on the first failure. Parsed (and coerced/defaulted) values are written
 * back onto the request object, so downstream handlers can trust their shape
 * and types.
 *
 * validate({ params: idParamSchema, body: createQuestionSchema })
 */
function validate({ params, query, body } = {}) {
  return (req, res, next) => {
    try {
      if (params) req.params = params.parse(req.params);
      if (query) req.query = query.parse(req.query);
      if (body) req.body = body.parse(req.body);
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        return res.status(400).json(formatZodError(err));
      }
      next(err);
    }
  };
}

module.exports = validate;
