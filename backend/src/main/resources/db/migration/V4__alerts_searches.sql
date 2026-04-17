-- ============================================================
-- V4: Alerts, Notifications, Saved Searches
-- ============================================================

-- ---- Alerts ----
-- One record per changed event per listing per user.
-- Immutable — never updated except for read status.
CREATE TABLE alerts (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    listing_id      UUID        REFERENCES listings(id) ON DELETE SET NULL,
    alert_type      VARCHAR(50) NOT NULL,   -- PRICE_DROP, PRICE_INCREASE, LISTING_REMOVED, etc.
    title           VARCHAR(255) NOT NULL,
    body            TEXT,
    old_value       VARCHAR(255),
    new_value       VARCHAR(255),
    is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_user ON alerts(user_id, created_at DESC);
CREATE INDEX idx_alerts_unread ON alerts(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_alerts_listing ON alerts(listing_id);

-- ---- Email Notifications ----
-- Tracks what emails were sent to avoid duplicates and support audit
CREATE TABLE email_notifications (
    id              BIGSERIAL   PRIMARY KEY,
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_id        UUID        REFERENCES alerts(id) ON DELETE SET NULL,
    subject         VARCHAR(255) NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, SENT, FAILED
    sent_at         TIMESTAMPTZ,
    error_message   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_notifs_user ON email_notifications(user_id);
CREATE INDEX idx_email_notifs_status ON email_notifications(status) WHERE status = 'PENDING';

-- ---- Saved Searches ----
CREATE TABLE saved_searches (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    notify_on_match BOOLEAN     NOT NULL DEFAULT TRUE,
    last_matched_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_saved_searches_user ON saved_searches(user_id);

-- ---- Saved Search Filters ----
-- Key-value filter pairs for maximum flexibility
CREATE TABLE saved_search_filters (
    id              BIGSERIAL   PRIMARY KEY,
    search_id       UUID        NOT NULL REFERENCES saved_searches(id) ON DELETE CASCADE,
    filter_key      VARCHAR(50) NOT NULL,   -- city, state, min_rent, max_rent, beds, etc.
    filter_value    VARCHAR(255) NOT NULL,
    filter_operator VARCHAR(20) NOT NULL DEFAULT 'EQ'  -- EQ, GTE, LTE, CONTAINS
);

CREATE INDEX idx_search_filters_search ON saved_search_filters(search_id);
