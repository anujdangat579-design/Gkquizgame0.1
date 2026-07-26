const userService = require('../services/userService');
const asyncHandler = require('../middleware/asyncHandler');

function handleServiceError(err, res) {
  if (err instanceof userService.ServiceError) {
    res.status(err.statusCode).json({ error: err.message });
    return true;
  }
  return false;
}

const listUsers = asyncHandler(async (req, res) => {
  const result = await userService.listUsers(req.query);
  res.json(result);
});

const searchUsers = asyncHandler(async (req, res) => {
  const result = await userService.searchUsers(req.query);
  res.json(result);
});

const getUser = asyncHandler(async (req, res, next) => {
  try {
    const user = await userService.getUserById(req.params.id);
    res.json(user);
  } catch (err) {
    if (!handleServiceError(err, res)) next(err);
  }
});

const blockUser = asyncHandler(async (req, res, next) => {
  try {
    const user = await userService.blockUser(req.params.id, {
      reason: req.body.reason,
      actorId: req.user.id,
    });
    res.json(user);
  } catch (err) {
    if (!handleServiceError(err, res)) next(err);
  }
});

const unblockUser = asyncHandler(async (req, res, next) => {
  try {
    const user = await userService.unblockUser(req.params.id, {
      reason: req.body.reason,
      actorId: req.user.id,
    });
    res.json(user);
  } catch (err) {
    if (!handleServiceError(err, res)) next(err);
  }
});

const suspendUser = asyncHandler(async (req, res, next) => {
  try {
    const user = await userService.suspendUser(req.params.id, {
      reason: req.body.reason,
      days: req.body.days,
      until: req.body.until,
      actorId: req.user.id,
    });
    res.json(user);
  } catch (err) {
    if (!handleServiceError(err, res)) next(err);
  }
});

module.exports = {
  listUsers,
  searchUsers,
  getUser,
  blockUser,
  unblockUser,
  suspendUser,
};
