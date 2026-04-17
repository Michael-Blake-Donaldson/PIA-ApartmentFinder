-- ============================================================
-- V6: Seed data — admin user and initial roles
-- ============================================================
-- Note: Admin password is hashed here as a placeholder.
-- The real hash is generated at startup by AdminInitializationService
-- using PiaProperties.admin.initialPassword. This migration only ensures
-- the admin record exists; the service updates the hash on first boot.

INSERT INTO users (id, email, password_hash, full_name, email_verified, enabled)
VALUES (
    gen_random_uuid(),
    '${admin.email:admin@pia.local}',
    '$2a$12$placeholder_will_be_overwritten_by_init_service',
    'PIA Admin',
    TRUE,
    TRUE
)
ON CONFLICT (email) DO NOTHING;
