-- Cashfree-backed entry-fee payments. One row per created order.
--
-- Lifecycle: CREATED (order opened with Cashfree) -> PAID (webhook or
-- verify-status call confirmed the payment) -> consumed=TRUE the moment a
-- paid order is used to join the matchmaking queue -> match_id gets set once
-- that queue join actually produces a match (payment is now permanently
-- spent). If a consumed-but-not-yet-matched entry is cancelled or the socket
-- disconnects before pairing, consumed is reset to FALSE so the player can
-- re-queue with the same paid order instead of losing it.
CREATE TABLE IF NOT EXISTS payments (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cf_order_id    VARCHAR(64) UNIQUE NOT NULL,
  cf_payment_id  VARCHAR(64),
  order_amount   NUMERIC(10,2) NOT NULL,
  currency       VARCHAR(8) NOT NULL DEFAULT 'INR',
  status         VARCHAR(16) NOT NULL DEFAULT 'CREATED', -- CREATED | PAID | FAILED | EXPIRED
  match_criteria JSONB, -- {category, difficulty, questionCount} this entry fee was created for
  consumed       BOOLEAN NOT NULL DEFAULT FALSE, -- currently claiming a matchmaking-queue slot
  consumed_at    TIMESTAMPTZ,
  match_id       UUID REFERENCES matches(id), -- set once this paid entry actually produced a match
  paid_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);

-- Speeds up "does this user have a spendable paid order" lookups, which run
-- on every matchmaking:join.
CREATE INDEX IF NOT EXISTS idx_payments_user_spendable
  ON payments(user_id, created_at)
  WHERE status = 'PAID' AND consumed = FALSE;
