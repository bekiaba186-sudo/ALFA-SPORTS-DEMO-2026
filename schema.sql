-- ALFA Sports platform: conceptual production schema.
-- This schema is for architecture review only. It does not enable payments or real-money wagering.
-- Apply only after security review, jurisdictional legal approval, and migration testing.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE account_status AS ENUM ('pending_verification','active','suspended','closed');
CREATE TYPE ticket_status AS ENUM ('draft','accepted_demo','settled_demo','voided','rejected');
CREATE TYPE event_status AS ENUM ('scheduled','live','finished','postponed','cancelled');
CREATE TYPE ledger_entry_type AS ENUM ('demo_credit','demo_debit','adjustment','reversal');
CREATE TYPE verification_status AS ENUM ('not_started','pending','verified','failed','expired');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(64) UNIQUE NOT NULL,
  email VARCHAR(254) UNIQUE,
  phone_e164 VARCHAR(20) UNIQUE,
  password_hash TEXT NOT NULL,
  preferred_locale VARCHAR(8) NOT NULL DEFAULT 'en' CHECK (preferred_locale IN ('en','am','om')),
  status account_status NOT NULL DEFAULT 'pending_verification',
  verification_status verification_status NOT NULL DEFAULT 'not_started',
  date_of_birth DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX users_status_created_idx ON users(status, created_at DESC);

CREATE TABLE roles (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(40) UNIQUE NOT NULL,
  description TEXT
);
CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES users(id),
  role_id SMALLINT NOT NULL REFERENCES roles(id),
  assigned_by UUID REFERENCES users(id),
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, role_id)
);

CREATE TABLE providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  provider_type VARCHAR(40) NOT NULL,
  licence_reference TEXT,
  contract_status VARCHAR(30) NOT NULL DEFAULT 'not_reviewed',
  enabled BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sports (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(30) UNIQUE NOT NULL,
  name_i18n JSONB NOT NULL
);
CREATE TABLE competitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id SMALLINT NOT NULL REFERENCES sports(id),
  provider_id UUID REFERENCES providers(id),
  external_id VARCHAR(120),
  name VARCHAR(180) NOT NULL,
  region_code VARCHAR(8),
  active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(provider_id, external_id)
);
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES providers(id),
  external_id VARCHAR(120),
  name VARCHAR(180) NOT NULL,
  UNIQUE(provider_id, external_id)
);
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES competitions(id),
  home_team_id UUID NOT NULL REFERENCES teams(id),
  away_team_id UUID NOT NULL REFERENCES teams(id),
  provider_id UUID REFERENCES providers(id),
  external_id VARCHAR(120),
  starts_at TIMESTAMPTZ NOT NULL,
  status event_status NOT NULL DEFAULT 'scheduled',
  score_home SMALLINT,
  score_away SMALLINT,
  data_version BIGINT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(provider_id, external_id),
  CHECK(home_team_id <> away_team_id)
);
CREATE INDEX events_start_status_idx ON events(starts_at, status);

CREATE TABLE markets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id),
  market_code VARCHAR(50) NOT NULL,
  label_i18n JSONB NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'open',
  UNIQUE(event_id, market_code)
);
CREATE TABLE selections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  market_id UUID NOT NULL REFERENCES markets(id),
  selection_code VARCHAR(50) NOT NULL,
  label_i18n JSONB NOT NULL,
  UNIQUE(market_id, selection_code)
);
CREATE TABLE odds_snapshots (
  id BIGSERIAL PRIMARY KEY,
  selection_id UUID NOT NULL REFERENCES selections(id),
  decimal_odds NUMERIC(10,4) NOT NULL CHECK(decimal_odds > 1),
  provider_id UUID REFERENCES providers(id),
  source_version VARCHAR(120),
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX odds_selection_time_idx ON odds_snapshots(selection_id, captured_at DESC);

-- Demo-only tickets. Real-money ticket acceptance must not be enabled by this prototype.
CREATE TABLE demo_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  status ticket_status NOT NULL DEFAULT 'draft',
  demo_stake NUMERIC(14,2) NOT NULL CHECK(demo_stake > 0),
  illustrative_return NUMERIC(14,2),
  currency_label VARCHAR(20) NOT NULL DEFAULT 'DEMO_CREDITS',
  idempotency_key UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, idempotency_key)
);
CREATE TABLE demo_ticket_selections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES demo_tickets(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id),
  market_id UUID NOT NULL REFERENCES markets(id),
  selection_id UUID NOT NULL REFERENCES selections(id),
  odds_at_selection NUMERIC(10,4) NOT NULL CHECK(odds_at_selection > 1)
);

-- Append-only demo ledger. Never update/delete posted entries; use reversals.
CREATE TABLE demo_ledger (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  ticket_id UUID REFERENCES demo_tickets(id),
  entry_type ledger_entry_type NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK(amount <> 0),
  balance_after NUMERIC(14,2) NOT NULL CHECK(balance_after >= 0),
  reference_key VARCHAR(140) UNIQUE NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX demo_ledger_user_time_idx ON demo_ledger(user_id, created_at DESC);

CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  actor_user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(80),
  target_id VARCHAR(120),
  ip_hash TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_actor_time_idx ON audit_logs(actor_user_id, created_at DESC);

CREATE TABLE responsible_use_controls (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  self_excluded_until TIMESTAMPTZ,
  account_time_limit_minutes INTEGER,
  cooling_off_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE localization_strings (
  string_key VARCHAR(120) NOT NULL,
  locale VARCHAR(8) NOT NULL CHECK(locale IN ('en','am','om')),
  translated_text TEXT NOT NULL,
  PRIMARY KEY(string_key, locale)
);

-- Future regulated-money modules intentionally omitted:
-- payment accounts, deposits, withdrawals, real-money wallets, real-money tickets,
-- settlement payouts and tax/levy calculations require approved legal/compliance design.
