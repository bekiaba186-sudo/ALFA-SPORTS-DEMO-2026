CREATE EXTENSION IF NOT EXISTS pgcrypto;
DO $$ BEGIN CREATE TYPE account_status AS ENUM ('pending_verification','active','suspended','closed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE event_status AS ENUM ('scheduled','live','finished','postponed','cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE demo_ticket_status AS ENUM ('accepted_demo','settled_demo','voided'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE TABLE IF NOT EXISTS users (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), username VARCHAR(64) UNIQUE NOT NULL,
 email VARCHAR(254) UNIQUE, password_hash TEXT NOT NULL,
 preferred_locale VARCHAR(8) NOT NULL DEFAULT 'am' CHECK(preferred_locale IN ('en','am','om')),
 status account_status NOT NULL DEFAULT 'active', created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS roles (id SMALLSERIAL PRIMARY KEY, code VARCHAR(40) UNIQUE NOT NULL, description TEXT);
CREATE TABLE IF NOT EXISTS permissions (id SMALLSERIAL PRIMARY KEY, code VARCHAR(80) UNIQUE NOT NULL, description TEXT);
CREATE TABLE IF NOT EXISTS role_permissions (role_id SMALLINT REFERENCES roles(id) ON DELETE CASCADE, permission_id SMALLINT REFERENCES permissions(id) ON DELETE CASCADE, PRIMARY KEY(role_id,permission_id));
CREATE TABLE IF NOT EXISTS user_roles (user_id UUID REFERENCES users(id) ON DELETE CASCADE, role_id SMALLINT REFERENCES roles(id), assigned_by UUID REFERENCES users(id), assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY(user_id,role_id));
CREATE TABLE IF NOT EXISTS admin_sessions (sid VARCHAR NOT NULL PRIMARY KEY, sess JSON NOT NULL, expire TIMESTAMPTZ NOT NULL);
CREATE INDEX IF NOT EXISTS admin_sessions_expire_idx ON admin_sessions(expire);
CREATE TABLE IF NOT EXISTS sports (id SMALLSERIAL PRIMARY KEY, code VARCHAR(30) UNIQUE NOT NULL, name_i18n JSONB NOT NULL);
CREATE TABLE IF NOT EXISTS competitions (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sport_id SMALLINT REFERENCES sports(id), name VARCHAR(180) NOT NULL, region_code VARCHAR(8), active BOOLEAN NOT NULL DEFAULT true);
CREATE TABLE IF NOT EXISTS teams (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(180) NOT NULL);
CREATE TABLE IF NOT EXISTS events (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), competition_id UUID REFERENCES competitions(id), home_team_id UUID REFERENCES teams(id), away_team_id UUID REFERENCES teams(id), starts_at TIMESTAMPTZ NOT NULL, status event_status NOT NULL DEFAULT 'scheduled', created_at TIMESTAMPTZ NOT NULL DEFAULT now(), CHECK(home_team_id IS DISTINCT FROM away_team_id));
CREATE TABLE IF NOT EXISTS markets (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), event_id UUID REFERENCES events(id) ON DELETE CASCADE, market_code VARCHAR(50) NOT NULL, label_i18n JSONB NOT NULL DEFAULT '{}', status VARCHAR(20) NOT NULL DEFAULT 'closed', UNIQUE(event_id,market_code));
CREATE TABLE IF NOT EXISTS audit_logs (id BIGSERIAL PRIMARY KEY, actor_user_id UUID REFERENCES users(id), action VARCHAR(100) NOT NULL, target_type VARCHAR(80), target_id VARCHAR(120), metadata JSONB NOT NULL DEFAULT '{}', created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS audit_logs_time_idx ON audit_logs(created_at DESC);
CREATE TABLE IF NOT EXISTS demo_wallets (user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE, balance NUMERIC(14,2) NOT NULL DEFAULT 1000 CHECK(balance>=0), updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS demo_ledger (id BIGSERIAL PRIMARY KEY, user_id UUID REFERENCES users(id), amount NUMERIC(14,2) NOT NULL CHECK(amount<>0), balance_after NUMERIC(14,2) NOT NULL CHECK(balance_after>=0), entry_type VARCHAR(30) NOT NULL CHECK(entry_type IN ('demo_credit','demo_debit','adjustment','reversal')), reference_key VARCHAR(140) UNIQUE NOT NULL, note TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS demo_ledger_user_time_idx ON demo_ledger(user_id,created_at DESC);
CREATE TABLE IF NOT EXISTS demo_tickets (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID REFERENCES users(id), status demo_ticket_status NOT NULL DEFAULT 'accepted_demo', demo_stake NUMERIC(14,2) NOT NULL CHECK(demo_stake>0), illustrative_return NUMERIC(14,2), idempotency_key UUID NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(user_id,idempotency_key));
