-- Adds support for Mobile OTP login and Google login alongside the existing
-- username/password flow (used by admins and any password-based players).
-- Nothing here touches admin authentication: admins keep logging in with
-- password via the existing /api/auth/login endpoint, unaffected by this
-- migration or by any of the new OTP/Google routes.

-- password_hash is only meaningful for auth_provider = 'password'. OTP and
-- Google accounts never set one, so the NOT NULL constraint has to go.
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Google accounts may not always expose an email (rare, but allowed by the
-- OAuth spec), and OTP accounts never have one unless the user later links
-- it. Postgres allows multiple NULLs under a UNIQUE constraint, so this is
-- safe to relax.
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(64) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 'password' | 'otp' | 'google' — which flow created/owns this account.
-- A user can still hold a password AND have signed in with Google in the
-- past (email-linked), but this records how the account originated.
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(16) NOT NULL DEFAULT 'password';

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
