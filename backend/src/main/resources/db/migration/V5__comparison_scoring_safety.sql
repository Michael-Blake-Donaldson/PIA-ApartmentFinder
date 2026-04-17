-- ============================================================
-- V5: Comparison, Scoring, Safety Regions
-- ============================================================

-- ---- Comparison Sets ----
CREATE TABLE comparison_sets (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        VARCHAR(100) NOT NULL DEFAULT 'My Comparison',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comparison_sets_user ON comparison_sets(user_id);

-- ---- Comparison Items ----
CREATE TABLE comparison_items (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    comparison_id   UUID        NOT NULL REFERENCES comparison_sets(id) ON DELETE CASCADE,
    listing_id      UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    sort_order      SMALLINT    NOT NULL DEFAULT 0,
    added_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_comparison_listing UNIQUE (comparison_id, listing_id)
);

CREATE INDEX idx_comparison_items_set ON comparison_items(comparison_id);

-- ---- Apartment Scores ----
-- Persisted score snapshot for a listing+user pair. Recomputed on preference/data change.
CREATE TABLE apartment_scores (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id              UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    user_id                 UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_score             DECIMAL(5,2), -- 0.00 to 100.00
    score_price             DECIMAL(5,2),
    score_size              DECIMAL(5,2),
    score_commute           DECIMAL(5,2),
    score_safety            DECIMAL(5,2),
    score_pet_friendly      DECIMAL(5,2),
    score_parking           DECIMAL(5,2),
    score_amenities         DECIMAL(5,2),
    score_breakdown         TEXT,           -- JSON: detailed explanation per dimension
    commute_seconds         INTEGER,        -- raw travel-time result (if available)
    commute_mode            VARCHAR(20),    -- DRIVE, TRANSIT, WALK
    commute_provider        VARCHAR(50),    -- which provider generated this
    safety_score            DECIMAL(5,2),
    safety_provider         VARCHAR(50),
    safety_confidence       VARCHAR(20),    -- HIGH, MEDIUM, LOW, UNAVAILABLE
    computed_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_score_listing_user UNIQUE (listing_id, user_id)
);

CREATE INDEX idx_scores_user ON apartment_scores(user_id);
CREATE INDEX idx_scores_listing ON apartment_scores(listing_id);

-- ---- Safety Regions ----
-- Admin-seeded placeholder data for demo/testing.
-- Structure supports real third-party data integration later.
CREATE TABLE safety_regions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    region_name         VARCHAR(255) NOT NULL,
    city                VARCHAR(100),
    state               VARCHAR(100),
    zip_code            VARCHAR(20),
    safety_score        DECIMAL(5,2) NOT NULL,  -- 0.00 to 100.00 (higher = safer)
    data_source         VARCHAR(100) NOT NULL DEFAULT 'MANUAL_SEED',
    confidence          VARCHAR(20)  NOT NULL DEFAULT 'LOW',
    notes               TEXT,
    effective_date      DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_safety_regions_geo ON safety_regions(city, state);
CREATE INDEX idx_safety_regions_zip ON safety_regions(zip_code);
