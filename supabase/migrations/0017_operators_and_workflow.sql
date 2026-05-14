-- =========================================================
-- DJAWAL V2 — Sprint B : Opérateurs Touristiques — Partie 2
-- Enums + colonnes opérateur + workflow status unifié
-- =========================================================
-- Prérequis : migration 0016 appliquée (rôle tourist_operator committé)
-- =========================================================

-- =====================================================================
-- 1. ENUMS — Sous-types d'opérateur, mode de composition, statut soumission
-- =====================================================================

-- Sous-types d'opérateur touristique (4 valeurs, transport reporté à plus tard)
CREATE TYPE operator_type AS ENUM (
  'travel_agency',          -- Agence de voyage
  'restaurant',             -- Restaurant traditionnel
  'accommodation_provider', -- Hébergeur (hôtel, gîte, etc.)
  'artisan'                 -- Artisan traditionnel
);
COMMENT ON TYPE operator_type IS 'Sous-catégorie d''opérateur touristique. Le transport (rail/air/maritime/road) est reporté.';

-- Rôle créateur d'un voyage (pour différencier signature guide vs agence vs hébergeur)
CREATE TYPE trip_creator_role AS ENUM (
  'guide_senior',
  'guide_junior',
  'travel_agency',
  'accommodation_provider'
);
COMMENT ON TYPE trip_creator_role IS 'Type de créateur d''un voyage — pilote l''affichage de la signature publique.';

-- Mode de composition d'un voyage
CREATE TYPE composition_mode AS ENUM (
  'djawal_catalog',  -- Composé depuis le catalogue Djawal (resources cliquables)
  'agency_package'   -- Package indépendant (programme libre, jour par jour)
);
COMMENT ON TYPE composition_mode IS 'Mode de composition du voyage : catalogue Djawal (resources reliées) ou package autonome.';

-- Statut de soumission générique (pour accommodations, restaurants, activities)
-- Workflow : draft → pending_review → published (ou rejected)
CREATE TYPE submission_status AS ENUM (
  'draft',
  'pending_review',
  'published',
  'rejected'
);
COMMENT ON TYPE submission_status IS 'Workflow de soumission pour les ressources créées par les opérateurs ou guides.';


-- =====================================================================
-- 2. EXTENSIONS DE LA TABLE PROFILES
-- =====================================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS operator_type operator_type,
  ADD COLUMN IF NOT EXISTS company_name TEXT,
  ADD COLUMN IF NOT EXISTS company_registration TEXT, -- Registre du commerce algérien
  ADD COLUMN IF NOT EXISTS commercial_register_url TEXT, -- URL doc RC scanné
  ADD COLUMN IF NOT EXISTS slug TEXT UNIQUE, -- Pour URLs propres /operateurs/:slug ou /guides/:slug
  ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}', -- Vitrine photos pour la fiche profil
  ADD COLUMN IF NOT EXISTS specialties TEXT[] DEFAULT '{}'; -- Tags libres pour la fiche profil

CREATE INDEX IF NOT EXISTS idx_profiles_operator_type ON profiles(operator_type) WHERE operator_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_slug ON profiles(slug) WHERE slug IS NOT NULL;

COMMENT ON COLUMN profiles.operator_type IS 'Si role = tourist_operator, précise le sous-type. NULL sinon.';
COMMENT ON COLUMN profiles.slug IS 'Slug pour URL publique (ex: atelier-de-saida-tapis-kabyles).';


-- =====================================================================
-- 3. EXTENSIONS DES TABLES PRODUITS (accommodations, restaurants, activities)
--    Workflow status + createur identifié
-- =====================================================================

-- Accommodations
ALTER TABLE accommodations
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS status submission_status NOT NULL DEFAULT 'published',
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS review_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_accommodations_status ON accommodations(status);
CREATE INDEX IF NOT EXISTS idx_accommodations_creator ON accommodations(created_by) WHERE created_by IS NOT NULL;

-- Restaurants
ALTER TABLE restaurants
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS status submission_status NOT NULL DEFAULT 'published',
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS review_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_restaurants_status ON restaurants(status);
CREATE INDEX IF NOT EXISTS idx_restaurants_creator ON restaurants(created_by) WHERE created_by IS NOT NULL;

-- Activities
ALTER TABLE activities
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS status submission_status NOT NULL DEFAULT 'published',
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS review_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_activities_status ON activities(status);
CREATE INDEX IF NOT EXISTS idx_activities_creator ON activities(created_by) WHERE created_by IS NOT NULL;

-- Backfill : tous les enregistrements existants étaient validés par admin = published
-- (déjà fait par le DEFAULT 'published', mais on s'assure pour les anciennes lignes)
UPDATE accommodations SET status = 'published' WHERE validated_at IS NOT NULL AND status != 'published';
UPDATE restaurants    SET status = 'published' WHERE validated_at IS NOT NULL AND status != 'published';
UPDATE activities     SET status = 'published' WHERE validated_at IS NOT NULL AND status != 'published';


-- =====================================================================
-- 4. EXTENSION DE LA TABLE TRIPS
--    creator_role, composition_mode, itinerary_json, packages
-- =====================================================================

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS creator_role trip_creator_role,
  ADD COLUMN IF NOT EXISTS composition_mode composition_mode NOT NULL DEFAULT 'djawal_catalog',
  ADD COLUMN IF NOT EXISTS itinerary_json JSONB, -- Structure libre jour par jour (mode agency_package)
  ADD COLUMN IF NOT EXISTS package_inclusions TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS package_exclusions TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS included_guide_id UUID REFERENCES profiles(id); -- Guide optionnellement inclus dans un package

CREATE INDEX IF NOT EXISTS idx_trips_creator_role ON trips(creator_role) WHERE creator_role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trips_composition_mode ON trips(composition_mode);

-- Backfill : déduire creator_role des trips existants à partir du rôle du créateur
UPDATE trips t SET creator_role = (
  CASE p.role
    WHEN 'guide_senior' THEN 'guide_senior'::trip_creator_role
    WHEN 'guide_junior' THEN 'guide_junior'::trip_creator_role
    ELSE 'guide_junior'::trip_creator_role -- fallback prudent
  END
)
FROM profiles p
WHERE p.id = t.created_by AND t.creator_role IS NULL;

COMMENT ON COLUMN trips.composition_mode IS 'djawal_catalog (resources cliquables) ou agency_package (programme libre)';
COMMENT ON COLUMN trips.itinerary_json IS 'Structure libre jour par jour [{day,title,description,meals,accommodation}]. NULL si composition_mode=djawal_catalog.';
COMMENT ON COLUMN trips.included_guide_id IS 'Si une agence/hébergeur inclut un guide dans son package, son ID est ici.';


-- =====================================================================
-- 5. MISE À JOUR DU TRIGGER DE STATUS POUR TRIPS
--    Ajout : opérateurs (agence, hébergeur) passent par pending_review
-- =====================================================================

CREATE OR REPLACE FUNCTION enforce_trip_status_by_role()
RETURNS TRIGGER AS $$
BEGIN
  -- Workflow : seul guide_senior peut auto-publier
  IF NEW.status = 'published' THEN
    IF current_user_role() = 'guide_senior' THEN
      NEW.published_at := COALESCE(NEW.published_at, NOW());
    ELSIF current_user_role() IN ('guide_junior', 'tourist_operator') THEN
      -- Forcer pending_review pour tous sauf guide_senior et super_admin
      NEW.status := 'pending_review';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION enforce_trip_status_by_role IS 'Force pending_review pour guide_junior et tourist_operator. Guide Senior auto-publie.';
