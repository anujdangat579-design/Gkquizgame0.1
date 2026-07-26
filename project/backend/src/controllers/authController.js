const authService = require('../services/authService');
const asyncHandler = require('../middleware/asyncHandler');

function requestMeta(req) {
  return { ipAddress: req.ip, userAgent: req.get('user-agent') };
}

const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body, requestMeta(req));
  res.status(201).json(result);
});

const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body, requestMeta(req));
  res.json(result);
});

const refresh = asyncHandler(async (req, res) => {
  const tokens = await authService.refresh(req.body);
  res.json(tokens);
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.body);
  res.json({ success: true });
});

const me = asyncHandler(async (req, res) => {
  const user = await authService.getProfile(req.user.id);
  res.json({ user });
});

const updateProfile = asyncHandler(async (req, res) => {
  const user = await authService.updateProfile(req.user.id, req.body);
  res.json({ user });
});

const requestOtp = asyncHandler(async (req, res) => {
  const result = await authService.requestOtp(req.body, requestMeta(req));
  res.json(result);
});

const verifyOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyOtp(req.body, requestMeta(req));
  res.status(result.isNewUser ? 201 : 200).json(result);
});

const googleLogin = asyncHandler(async (req, res) => {
  const result = await authService.googleLogin(req.body, requestMeta(req));
  res.status(result.isNewUser ? 201 : 200).json(result);
});

module.exports = {
  register,
  login,
  refresh,
  logout,
  me,
  updateProfile,
  requestOtp,
  verifyOtp,
  googleLogin,
};
