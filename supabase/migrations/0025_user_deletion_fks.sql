-- ============================================================================
-- Migration 0025 — FK ON DELETE pour suppression user admin
-- ----------------------------------------------------------------------------
-- Préalable pour activer la suppression d'utilisateur depuis /admin/users/:id.
--
-- Plusieurs FK de profiles(id) n'ont pas de clause ON DELETE, donc le défaut
-- (NO ACTION) bloquerait la suppression si l'user a créé des ressources.
--
-- Décisions :
--   - accommodations.created_by  → ON DELETE SET NULL (la ressource survit, créateur anonyme)
--   - restaurants.created_by      → ON DELETE SET NULL
--   - activities.created_by       → ON DELETE SET NULL
--   - sites.validated_by          → ON DELETE SET NULL (validation conservée mais anonyme)
--   - trips.reviewed_by           → ON DELETE SET NULL (modération conservée)
--
-- NB : les FK qui sont déjà ON DELETE CASCADE (trips.created_by, memories.author_id,
-- user_favorites, user_reviews, kyc_documents) restent inchangées : si on supprime
-- un user, son contenu personnel disparaît.
-- ============================================================================

BEGIN;

-- ============================================================================
-- accommodations.created_by → ON DELETE SET NULL
-- ============================================================================
ALTER TABLE accommodations
  DROP CONSTRAINT IF EXISTS accommodations_created_by_fkey;
ALTER TABLE accommodations
  ADD CONSTRAINT accommodations_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- restaurants.created_by → ON DELETE SET NULL
-- ============================================================================
ALTER TABLE restaurants
  DROP CONSTRAINT IF EXISTS restaurants_created_by_fkey;
ALTER TABLE restaurants
  ADD CONSTRAINT restaurants_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- activities.created_by → ON DELETE SET NULL
-- ============================================================================
ALTER TABLE activities
  DROP CONSTRAINT IF EXISTS activities_created_by_fkey;
ALTER TABLE activities
  ADD CONSTRAINT activities_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- sites.validated_by → ON DELETE SET NULL
-- ============================================================================
ALTER TABLE sites
  DROP CONSTRAINT IF EXISTS sites_validated_by_fkey;
ALTER TABLE sites
  ADD CONSTRAINT sites_validated_by_fkey
  FOREIGN KEY (validated_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- trips.reviewed_by → ON DELETE SET NULL (si la colonne existe)
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'trips' AND column_name = 'reviewed_by') THEN
    ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_reviewed_by_fkey;
    ALTER TABLE trips
      ADD CONSTRAINT trips_reviewed_by_fkey
      FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================================
-- destinations.validated_by → ON DELETE SET NULL (si la colonne existe)
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'destinations' AND column_name = 'validated_by') THEN
    ALTER TABLE destinations DROP CONSTRAINT IF EXISTS destinations_validated_by_fkey;
    ALTER TABLE destinations
      ADD CONSTRAINT destinations_validated_by_fkey
      FOREIGN KEY (validated_by) REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

COMMIT;
