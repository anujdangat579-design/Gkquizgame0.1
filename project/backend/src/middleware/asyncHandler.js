// Wraps an async route/controller handler so any rejected promise or thrown
// error is forwarded to Express's error-handling middleware via next(err),
// instead of needing a try/catch in every single controller function.
//
// Usage:
//   router.get('/thing', asyncHandler(async (req, res) => { ... }));
function asyncHandler(fn) {
  return function wrapped(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
