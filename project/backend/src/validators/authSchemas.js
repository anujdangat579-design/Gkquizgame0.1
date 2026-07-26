const { z } = require('zod');

const registerSchema = z.object({
  username: z
    .string({ required_error: 'Username must be 3-32 chars, letters/numbers/underscore only' })
    .trim()
    .min(3, 'Username must be 3-32 chars, letters/numbers/underscore only')
    .max(32, 'Username must be 3-32 chars, letters/numbers/underscore only')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username must be 3-32 chars, letters/numbers/underscore only'),
  email: z
    .string({ required_error: 'Valid email required' })
    .trim()
    .email('Valid email required')
    .transform((v) => v.toLowerCase()),
  password: z
    .string({ required_error: 'Password must be at least 8 characters' })
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be at least 8 characters'),
});

const loginSchema = z.object({
  username: z.string({ required_error: 'Username or email required' }).trim().min(1, 'Username or email required'),
  password: z.string({ required_error: 'Password required' }).min(1, 'Password required'),
});

const refreshSchema = z.object({
  refreshToken: z.string({ required_error: 'refreshToken is required' }).min(1, 'refreshToken is required'),
});

// Logout is best-effort: an absent/empty refreshToken is fine (see
// authController.logout), so this only validates *shape* when one is given.
const logoutSchema = z.object({
  refreshToken: z.string().optional(),
});

// E.164 format: optional leading '+', 8-15 digits total (ITU-T recommendation).
const phoneSchema = z
  .string({ required_error: 'A valid phone number in E.164 format (e.g. +14155552671) is required' })
  .trim()
  .regex(/^\+?[1-9]\d{7,14}$/, 'A valid phone number in E.164 format (e.g. +14155552671) is required');

const otpRequestSchema = z.object({
  phone: phoneSchema,
});

const otpVerifySchema = z.object({
  phone: phoneSchema,
  otp: z
    .string({ required_error: '6-digit OTP is required' })
    .trim()
    .regex(/^\d{6}$/, '6-digit OTP is required'),
});

const googleLoginSchema = z.object({
  idToken: z.string({ required_error: 'idToken is required' }).min(1, 'idToken is required'),
});

const updateProfileSchema = z
  .object({
    name: z.string().trim().min(1).max(100).optional(),
    avatarUrl: z.string().trim().url('avatarUrl must be a valid URL').optional(),
    email: z.string().trim().email('Valid email required').transform((v) => v.toLowerCase()).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field is required' });

module.exports = {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  otpRequestSchema,
  otpVerifySchema,
  googleLoginSchema,
  updateProfileSchema,
};
