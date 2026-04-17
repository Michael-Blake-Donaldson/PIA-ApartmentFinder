-- ============================================================
-- V1: Auth, Users, and Settings
-- ============================================================

-- Enable UUID generation (PostgreSQL built-in)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---- Roles ----
CREATE TABLE roles (
    id      SMALLSERIAL PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE  -- e.g. ROLE_USER, ROLE_ADMIN
);

INSERT INTO roles (name) VALUES ('ROLE_USER'), ('ROLE_ADMIN');

-- ---- Users ----
CREATE TABLE users (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255),
    avatar_url      VARCHAR(512),
    email_verified  BOOLEAN     NOT NULL DEFAULT FALSE,
    enabled         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ          -- soft delete; null = active
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;

-- ---- User Roles (join table) ----
CREATE TABLE user_roles (
    user_id UUID     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id SMALLINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- ---- Refresh Tokens ----
-- Stored in DB for revocation support. Rotated on each use.
CREATE TABLE refresh_tokens (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(512) NOT NULL UNIQUE,  -- SHA-256 of the raw token
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- ---- User Settings ----
CREATE TABLE user_settings (
    user_id                     UUID        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    -- Notification preferences
    notify_price_drop           BOOLEAN     NOT NULL DEFAULT TRUE,
    notify_price_increase       BOOLEAN     NOT NULL DEFAULT FALSE,
    notify_availability_change  BOOLEAN     NOT NULL DEFAULT TRUE,
    notify_listing_removed      BOOLEAN     NOT NULL DEFAULT TRUE,
    notify_new_search_match     BOOLEAN     NOT NULL DEFAULT TRUE,
    -- Email digest vs immediate
    email_mode                  VARCHAR(20) NOT NULL DEFAULT 'IMMEDIATE',  -- IMMEDIATE | DIGEST
    -- User's currency/locale
    locale                      VARCHAR(10) NOT NULL DEFAULT 'en-US',
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---- Commute Origins ----
-- Users can store named locations (home, work) for commute scoring
CREATE TABLE commute_origins (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label       VARCHAR(100) NOT NULL,  -- "Work", "Mom's House", etc.
    address     TEXT        NOT NULL,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    is_primary  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_commute_origins_user ON commute_origins(user_id);

-- ---- Scoring Preferences ----
-- Weights for personalized apartment scoring
CREATE TABLE scoring_preferences (
    user_id             UUID    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    weight_price        SMALLINT NOT NULL DEFAULT 30,
    weight_size         SMALLINT NOT NULL DEFAULT 15,
    weight_commute      SMALLINT NOT NULL DEFAULT 20,
    weight_safety       SMALLINT NOT NULL DEFAULT 15,
    weight_pet_friendly SMALLINT NOT NULL DEFAULT 5,
    weight_parking      SMALLINT NOT NULL DEFAULT 5,
    weight_amenities    SMALLINT NOT NULL DEFAULT 10,
    max_acceptable_rent INTEGER,   -- used to normalize price scores
    preferred_commute_origin_id UUID REFERENCES commute_origins(id) ON DELETE SET NULL,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---- Audit Log ----
CREATE TABLE audit_logs (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     UUID        REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id   VARCHAR(100),
    detail      TEXT,
    ip_address  VARCHAR(50),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
