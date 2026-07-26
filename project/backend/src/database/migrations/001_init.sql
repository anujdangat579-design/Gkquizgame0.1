-- Core schema for the GK Quiz app. Money/payments live separately in
-- 004_payments.sql (Cashfree-backed matchmaking entry fee).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      VARCHAR(32) UNIQUE NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role          VARCHAR(16) NOT NULL DEFAULT 'player', -- 'player' | 'admin'
  is_blocked    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);

CREATE TABLE IF NOT EXISTS questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category        VARCHAR(64) NOT NULL,
  difficulty      VARCHAR(16) NOT NULL, -- 'Easy' | 'Medium' | 'Hard'
  question_text   TEXT NOT NULL,
  options         JSONB NOT NULL,       -- e.g. ["A","B","C","D"]
  correct_index   SMALLINT NOT NULL,
  explanation     TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_by      UUID REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_questions_category_difficulty ON questions(category, difficulty);

CREATE TABLE IF NOT EXISTS matches (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_a_id      UUID NOT NULL REFERENCES users(id),
  player_b_id      UUID NOT NULL REFERENCES users(id),
  category         VARCHAR(64),
  difficulty       VARCHAR(16) NOT NULL,
  question_count   SMALLINT NOT NULL,
  question_ids     JSONB NOT NULL, -- ordered array of question ids used
  status           VARCHAR(16) NOT NULL DEFAULT 'in_progress', -- in_progress | completed | abandoned
  winner_id        UUID REFERENCES users(id),
  score_a          SMALLINT,
  score_b          SMALLINT,
  started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at     TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_matches_players ON matches(player_a_id, player_b_id);

CREATE TABLE IF NOT EXISTS match_answers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id),
  question_id  UUID NOT NULL REFERENCES questions(id),
  chosen_index SMALLINT,
  is_correct   BOOLEAN NOT NULL,
  answer_ms    INTEGER NOT NULL, -- time taken to answer, in ms
  answered_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_match_answers_match_id ON match_answers(match_id);

CREATE TABLE IF NOT EXISTS leaderboard_stats (
  user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  matches_played INTEGER NOT NULL DEFAULT 0,
  matches_won    INTEGER NOT NULL DEFAULT 0,
  total_correct  INTEGER NOT NULL DEFAULT 0,
  total_answered INTEGER NOT NULL DEFAULT 0,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
