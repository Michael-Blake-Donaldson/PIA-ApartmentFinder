-- ============================================================
-- V2: Listings, Images, Notes, Source Metadata
-- ============================================================

-- ---- Listings ----
-- Core apartment listing entity. Deduplication is by source_url (unique per user).
CREATE TABLE listings (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Source
    source_url          TEXT,
    source_domain       VARCHAR(255),
    is_manual_entry     BOOLEAN     NOT NULL DEFAULT FALSE,

    -- Property identity
    property_name       VARCHAR(255),
    street_address      VARCHAR(255),
    city                VARCHAR(100),
    state               VARCHAR(100),
    zip_code            VARCHAR(20),
    country             VARCHAR(10) NOT NULL DEFAULT 'US',
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    geocoded_at         TIMESTAMPTZ,

    -- Rent
    rent_min            INTEGER,    -- cents to avoid float issues
    rent_max            INTEGER,
    price_display_text  VARCHAR(100),

    -- Unit details
    bedrooms            DECIMAL(3,1),  -- 0 = studio, 1.5 = loft, etc.
    bathrooms           DECIMAL(3,1),
    square_footage      INTEGER,
    property_type       VARCHAR(50),  -- APARTMENT, CONDO, HOUSE, etc.
    unit_type           VARCHAR(50),

    -- Availability
    listing_status      VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, UNAVAILABLE, REMOVED, UNKNOWN
    availability_date   DATE,
    lease_terms         TEXT,        -- JSON array of terms

    -- Policies
    pet_policy          VARCHAR(30) DEFAULT 'UNKNOWN',  -- ALLOWED, NOT_ALLOWED, CATS_ONLY, etc.
    pet_policy_details  TEXT,
    parking             VARCHAR(30) DEFAULT 'UNKNOWN',  -- INCLUDED, AVAILABLE, PAID, NONE
    parking_details     TEXT,

    -- Features
    amenities           TEXT,        -- JSON array of amenity strings
    description         TEXT,
    contact_info        TEXT,

    -- Fees (in cents)
    application_fee     INTEGER,
    security_deposit    INTEGER,
    recurring_fees      TEXT,        -- JSON array of {name, amount, frequency}

    -- City search context (derived from listing address)
    city_search_radius_km   DECIMAL(8,2),  -- radius used for "related listing" searches
    city_centroid_lat       DOUBLE PRECISION,
    city_centroid_lng       DOUBLE PRECISION,

    -- Tracking metadata
    date_first_tracked      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_checked_at         TIMESTAMPTZ,
    last_changed_at         TIMESTAMPTZ,

    -- Soft delete
    deleted_at          TIMESTAMPTZ,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- One URL per user (don't create duplicate tracking for same listing)
    CONSTRAINT uq_listing_user_url UNIQUE NULLS NOT DISTINCT (user_id, source_url)
);

CREATE INDEX idx_listings_user ON listings(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_city_state ON listings(city, state) WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_rent ON listings(rent_min, rent_max) WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_status ON listings(listing_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_geo ON listings(latitude, longitude) WHERE latitude IS NOT NULL;

-- ---- Listing Images ----
CREATE TABLE listing_images (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    url         TEXT        NOT NULL,
    alt_text    VARCHAR(255),
    sort_order  SMALLINT    NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_listing_images_listing ON listing_images(listing_id);

-- ---- Listing Notes ----
CREATE TABLE listing_notes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT        NOT NULL,
    note_type   VARCHAR(20) NOT NULL DEFAULT 'GENERAL',  -- GENERAL, PRO, CON, QUESTION
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_listing_notes_listing ON listing_notes(listing_id);

-- ---- Parser Source Metadata ----
-- Tracks how a listing was obtained and how well the parser did
CREATE TABLE listing_source_metadata (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id          UUID        NOT NULL UNIQUE REFERENCES listings(id) ON DELETE CASCADE,
    adapter_name        VARCHAR(100),   -- e.g. "ApartmentsComAdapter"
    parser_confidence   DECIMAL(4,3),   -- 0.000 - 1.000
    parser_warnings     TEXT,           -- JSON array of warning strings
    extracted_fields    TEXT,           -- JSON: which fields were auto-extracted
    raw_page_hash       VARCHAR(64),    -- SHA-256 of last fetched page content
    last_parse_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
