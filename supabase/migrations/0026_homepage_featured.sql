-- ============================================================================
-- Migration 0026 — Admin HomePage : destinations vedettes + voyages signés
-- ----------------------------------------------------------------------------
-- Remplace le hard-code heroCards / signedTrips de HomePage.vue par des
-- colonnes is_featured_homepage + homepage_display_order que le super_admin
-- peut éditer depuis /admin/homepage.
--
-- Ajoute aussi un champ `tagline` (sous-titre court 1 ligne) sur destinations
-- pour les cards du carrousel mauresque ("Saharien · UNESCO" etc.).
-- ============================================================================

BEGIN;

-- =========================================================
-- 1. DESTINATIONS — Featured HomePage
-- =========================================================

ALTER TABLE destinations
  ADD COLUMN IF NOT EXISTS is_featured_homepage BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS homepage_display_order INT NOT NULL DEFAULT 999,
  ADD COLUMN IF NOT EXISTS tagline TEXT;

COMMENT ON COLUMN destinations.is_featured_homepage IS 'Si true, apparaît dans le carrousel mauresque de la HomePage.';
COMMENT ON COLUMN destinations.homepage_display_order IS 'Position dans le carrousel HomePage (0 = première, 999 = défaut/dernier).';
COMMENT ON COLUMN destinations.tagline IS 'Sous-titre court (ex: "Saharien · UNESCO") pour la card carrousel.';

-- Index partiel pour query rapide depuis HomePage.vue
CREATE INDEX IF NOT EXISTS idx_destinations_featured_homepage
  ON destinations(homepage_display_order)
  WHERE is_featured_homepage = true;

-- Backfill : marquer les 10 destinations actuellement hardcodées
-- (le super_admin pourra les décocher / réordonner ensuite via /admin/homepage)
UPDATE destinations SET
  is_featured_homepage = true,
  homepage_display_order = CASE
    WHEN name ILIKE 'Tassili%' OR name ILIKE '%Tassili%n%Ajjer%' THEN 1
    WHEN name ILIKE '%Casbah%Alger%' OR name = 'Alger' THEN 2
    WHEN name ILIKE 'Djurdjura' OR name ILIKE 'Tizi%Ouzou%' THEN 3
    WHEN name ILIKE 'Ghardaïa' OR name ILIKE 'Ghardaia' THEN 4
    WHEN name ILIKE 'Tipaza' OR name ILIKE 'Tipasa' THEN 5
    WHEN name ILIKE 'Constantine' THEN 6
    WHEN name ILIKE 'Timimoun' THEN 7
    WHEN name ILIKE 'Hoggar' OR name ILIKE 'Tamanrasset' THEN 8
    WHEN name ILIKE 'Tlemcen' THEN 9
    WHEN name ILIKE 'Djémila' OR name ILIKE 'Djemila' OR name ILIKE 'Setif' THEN 10
    ELSE 999
  END,
  tagline = COALESCE(tagline, CASE
    WHEN name ILIKE 'Tassili%'        THEN 'Saharien · UNESCO'
    WHEN name ILIKE '%Casbah%'         THEN 'Mauresque · UNESCO'
    WHEN name ILIKE 'Djurdjura%'      THEN 'Kabylie'
    WHEN name ILIKE 'Ghardaïa%'       THEN 'Saharien · UNESCO'
    WHEN name ILIKE 'Tipaza%'         THEN 'Mauresque · UNESCO'
    WHEN name ILIKE 'Constantine%'    THEN 'Aurès'
    WHEN name ILIKE 'Timimoun%'       THEN 'Saharien'
    WHEN name ILIKE 'Hoggar%'         THEN 'Saharien'
    WHEN name ILIKE 'Tlemcen%'        THEN 'Mauresque'
    WHEN name ILIKE 'Djémila%'        THEN 'Aurès · UNESCO'
    ELSE NULL
  END)
WHERE name ILIKE ANY (ARRAY[
  '%Tassili%', '%Casbah%', '%Alger%', 'Djurdjura%', 'Ghardaïa%', 'Ghardaia%',
  'Tipaza%', 'Tipasa%', 'Constantine%', 'Timimoun%', 'Hoggar%', 'Tamanrasset%',
  'Tlemcen%', 'Djémila%', 'Djemila%', 'Setif%'
]);


-- =========================================================
-- 2. TRIPS — Voyages signés HomePage
-- =========================================================

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS is_featured_homepage BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS homepage_display_order INT NOT NULL DEFAULT 999;

COMMENT ON COLUMN trips.is_featured_homepage IS 'Si true, apparaît dans la section "Voyages signés" de la HomePage (3 max).';
COMMENT ON COLUMN trips.homepage_display_order IS 'Position parmi les 3 voyages featured (0 = première, 999 = défaut).';

CREATE INDEX IF NOT EXISTS idx_trips_featured_homepage
  ON trips(homepage_display_order)
  WHERE is_featured_homepage = true AND status = 'published';

-- Pas de backfill auto pour trips : les titres hardcodés ne correspondent pas
-- forcément à des trips réels en BDD. Le super_admin choisira manuellement via /admin/homepage.


-- =========================================================
-- 3. RLS : super_admin peut lire/écrire ces colonnes
-- =========================================================
-- Pas besoin de nouvelle policy : les policies existantes
-- (destinations_admin_write, trips_owner_update) couvrent déjà l'écriture par
-- super_admin via current_user_role() = 'super_admin'.

COMMIT;
