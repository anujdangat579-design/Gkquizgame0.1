-- 005: Adds account-status tracking to users so the admin panel can block,
-- unblock, and (temporarily) suspend accounts.
--
-- status:
--   active    - normal, can log in
--   blocked   - indefinite, admin-imposed, must be explicitly unblocked
--   suspended - temporary, auto-expires at suspended_until
--
-- status_changed_by is nullable (not NOT NULL) so it survives the admin
-- account itself later being deleted; ON DELETE SET NULL keeps the audit
-- trail intact without a dangling FK.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'blocked', 'suspended')),
  ADD COLUMN IF NOT EXISTS suspended_until TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS status_reason TEXT NULL,
  ADD COLUMN IF NOT EXISTS status_changed_by UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMPTZ NULL;

-- Enforce the "only suspended accounts carry an expiry" invariant at the DB
-- level, not just in application code.
ALTER TABLE users
  ADD CONSTRAINT IF NOT EXISTS chk_suspended_until_only_when_suspended
    CHECK (
      (status = 'suspended' AND suspended_until IS NOT NULL)
      OR (status != 'suspended' AND suspended_until IS NULL)
    );

CREATE INDEX IF NOT EXISTS idx_users_status ON users (status);

-- Trigram search across the fields the admin search box hits, so
-- `ILIKE '%term%'` queries in userModel.searchUsers don't full-scan as the
-- table grows. Requires pg_trgm (available by default on most managed
-- Postgres providers, including Render/Supabase/RDS).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_users_username_trgm ON users USING gin (username gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_users_email_trgm ON users USING gin (email gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_users_phone_trgm ON users USING gin (phone gin_trgm_ops);
