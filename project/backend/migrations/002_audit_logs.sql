-- Append-only audit trail for admin actions, authentication attempts,
-- payments, and score changes. Rows are only ever inserted, never updated
-- or deleted, so this table doubles as a tamper-evident log.
--
-- actor_id intentionally has ON DELETE SET NULL (not CASCADE): a log entry
-- must survive even if the acting account is later deleted, which is why
-- actor_username is also denormalized here as a point-in-time snapshot.

CREATE TABLE IF NOT EXISTS audit_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category       VARCHAR(16) NOT NULL, -- 'auth' | 'admin' | 'payment' | 'score'
  action         VARCHAR(64) NOT NULL, -- e.g. 'LOGIN_SUCCESS', 'QUESTION_DELETED', 'MATCH_COMPLETED'
  status         VARCHAR(16) NOT NULL DEFAULT 'success', -- 'success' | 'failure'
  actor_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  actor_username VARCHAR(32),
  entity_type    VARCHAR(32), -- e.g. 'question', 'match', 'user', 'payment'
  entity_id      UUID,
  ip_address     VARCHAR(64),
  user_agent     TEXT,
  metadata       JSONB, -- freeform structured details (diffs, reasons, amounts, etc.)
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_category_created_at ON audit_logs(category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
