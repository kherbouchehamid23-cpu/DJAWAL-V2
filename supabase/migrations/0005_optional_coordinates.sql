-- =========================================================
-- DJAWAL V2 — Coordonnées GPS optionnelles
-- =========================================================

ALTER TABLE destinations ALTER COLUMN coordinates DROP NOT NULL;
ALTER TABLE hotels       ALTER COLUMN coordinates DROP NOT NULL;
ALTER TABLE sites        ALTER COLUMN coordinates DROP NOT NULL;
ALTER TABLE restaurants  ALTER COLUMN coordinates DROP NOT NULL;
