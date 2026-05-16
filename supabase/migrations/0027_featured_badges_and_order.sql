-- ============================================================================
-- Migration 0027 — Badges promotion + ordre d'affichage manuel
-- ----------------------------------------------------------------------------
-- Sprint 2 — featured_label enum :
--   Permet à l'admin de marquer un contenu comme "vedette", "coup de cœur"
--   ou "tendance". Affiché en badge sur les cards listings publiques.
--
-- Sprint 4 — display_order :
--   Permet à l'admin de définir l'ordre d'affichage des destinations dans
--   les listings publics (/voyages, page destinations). Plus le chiffre est
--   petit, plus la destination apparaît en premier.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. ENUM featured_label
-- ============================================================================
DO $$ BEGIN
  CREATE TYPE featured_label AS ENUM ('vedette', 'coup_de_coeur', 'tendance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- 2. COLONNES featured_label sur les tables
-- ============================================================================
-- NULL = aucun badge. Les valeurs : 'vedette', 'coup_de_coeur', 'tendance'.

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS featured_label featured_label;
ALTER TABLE accommodations
  ADD COLUMN IF NOT EXISTS featured_label featured_label;
ALTER TABLE restaurants
  ADD COLUMN IF NOT EXISTS featured_label featured_label;
ALTER TABLE activities
  ADD COLUMN IF NOT EXISTS featured_label featured_label;
ALTER TABLE sites
  ADD COLUMN IF NOT EXISTS featured_label featured_label;

-- Index partiels pour query rapide des contenus avec badge
CREATE INDEX IF NOT EXISTS idx_trips_featured_label
  ON trips(featured_label) WHERE featured_label IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_accommodations_featured_label
  ON accommodations(featured_label) WHERE featured_label IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_restaurants_featured_label
  ON restaurants(featured_label) WHERE featured_label IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_activities_featured_label
  ON activities(featured_label) WHERE featured_label IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sites_featured_label
  ON sites(featured_label) WHERE featured_label IS NOT NULL;

COMMENT ON COLUMN trips.featured_label IS 'Badge éditorial admin : vedette / coup_de_coeur / tendance. NULL = pas de badge.';
COMMENT ON COLUMN accommodations.featured_label IS 'Badge éditorial admin.';
COMMENT ON COLUMN restaurants.featured_label IS 'Badge éditorial admin.';
COMMENT ON COLUMN activities.featured_label IS 'Badge éditorial admin.';
COMMENT ON COLUMN sites.featured_label IS 'Badge éditorial admin.';

-- ============================================================================
-- 3. display_order sur destinations
-- ============================================================================
ALTER TABLE destinations
  ADD COLUMN IF NOT EXISTS display_order INT NOT NULL DEFAULT 999;

CREATE INDEX IF NOT EXISTS idx_destinations_display_order
  ON destinations(display_order, name);

COMMENT ON COLUMN destinations.display_order IS 'Ordre d''affichage manuel dans les listings publics (0 = première, 999 = défaut alphabétique).';

COMMIT;
