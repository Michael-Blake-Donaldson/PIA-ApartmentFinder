-- ============================================================
-- V3: Snapshots, Change Events, Parser Runs
-- ============================================================

-- ---- Listing Snapshots ----
-- Append-only versioned state of a listing at a point in time.
-- Never updated — only inserted. Diffs are computed between consecutive rows.
CREATE TABLE listing_snapshots (
    id                  BIGSERIAL   PRIMARY KEY,
    listing_id          UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,

    -- Captured values at this point in time
    rent_min            INTEGER,
    rent_max            INTEGER,
    listing_status      VARCHAR(30),
    availability_date   DATE,
    pet_policy          VARCHAR(30),
    parking             VARCHAR(30),
    amenities           TEXT,        -- JSON
    description_hash    VARCHAR(64), -- SHA-256 of description for change detection
    recurring_fees      TEXT,        -- JSON
    page_hash           VARCHAR(64), -- SHA-256 of full page HTML

    -- Change summary vs previous snapshot
    changes_detected    TEXT,        -- JSON array of ChangeType enum strings
    is_first_snapshot   BOOLEAN     NOT NULL DEFAULT FALSE,
    page_unreachable    BOOLEAN     NOT NULL DEFAULT FALSE,

    captured_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_snapshots_listing ON listing_snapshots(listing_id, captured_at DESC);

-- ---- Parser Runs ----
-- Log each time a URL was fetched and parsed (for admin visibility)
CREATE TABLE parser_runs (
    id              BIGSERIAL   PRIMARY KEY,
    listing_id      UUID        REFERENCES listings(id) ON DELETE SET NULL,
    source_url      TEXT        NOT NULL,
    adapter_name    VARCHAR(100),
    status          VARCHAR(20) NOT NULL,  -- SUCCESS, PARTIAL, FAILED, TIMEOUT
    duration_ms     INTEGER,
    confidence      DECIMAL(4,3),
    triggered_by    VARCHAR(20) NOT NULL,  -- USER, SCHEDULER, ADMIN
    triggered_by_id UUID,
    error_message   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_parser_runs_listing ON parser_runs(listing_id);
CREATE INDEX idx_parser_runs_created ON parser_runs(created_at DESC);
CREATE INDEX idx_parser_runs_status  ON parser_runs(status);

-- ---- Parser Failures ----
-- Detailed failure records for admin inspection
CREATE TABLE parser_failures (
    id              BIGSERIAL   PRIMARY KEY,
    parser_run_id   BIGINT      REFERENCES parser_runs(id) ON DELETE CASCADE,
    source_url      TEXT        NOT NULL,
    adapter_name    VARCHAR(100),
    error_type      VARCHAR(100),
    error_detail    TEXT,
    stack_excerpt   TEXT,       -- Just first N chars of stack trace, not full
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_parser_failures_run ON parser_failures(parser_run_id);
CREATE INDEX idx_parser_failures_created ON parser_failures(created_at DESC);
