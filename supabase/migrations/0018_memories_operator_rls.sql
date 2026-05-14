-- =========================================================
-- DJAWAL V2 — Sprint B : Opérateurs Touristiques — Partie 3
-- Extension memories + Matrice can_operator_submit + RLS opérateurs
-- =========================================================

-- =====================================================================
-- 1. EXTENSION DE LA TABLE MEMORIES
--    Permet de rattacher un souvenir à un opérateur, activité, hébergement, restaurant
-- =====================================================================

ALTER TABLE memories
  ADD COLUMN IF NOT EXISTS related_operator_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_activity_id UUID REFERENCES activities(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_accommodation_id UUID REFERENCES accommodations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_restaurant_id UUID REFERENCES restaurants(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_memories_related_operator ON memories(related_operator_id) WHERE related_operator_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_memories_related_activity ON memories(related_activity_id) WHERE related_activity_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_memories_related_accommodation ON memories(related_accommodation_id) WHERE related_accommodation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_memories_related_restaurant ON memories(related_restaurant_id) WHERE related_restaurant_id IS NOT NULL;

COMMENT ON COLUMN memories.related_operator_id IS 'Souvenir rattaché à un opérateur (artisan rencontré, restaurateur, hébergeur, agence).';
COMMENT ON COLUMN memories.related_activity_id IS 'Souvenir rattaché à une activité (atelier artisanat, trek, plongée).';
COMMENT ON COLUMN memories.related_accommodation_id IS 'Souvenir rattaché à un hébergement précis.';
COMMENT ON COLUMN memories.related_restaurant_id IS 'Souvenir rattaché à un restaurant précis.';


-- =====================================================================
-- 2. MATRICE DE CAPACITÉ — Quel opérateur peut soumettre quel type de produit
--    Référence : doc architecture Sprint B
-- =====================================================================

CREATE OR REPLACE FUNCTION can_operator_submit(
  p_operator_type operator_type,
  p_resource_type TEXT  -- 'accommodation', 'restaurant', 'activity', 'trip'
)
RETURNS BOOLEAN
LANGUAGE SQL IMMUTABLE
AS $$
  SELECT CASE
    -- Hébergeur : périmètre maximal (tout sauf si fonctionnel exclu)
    WHEN p_operator_type = 'accommodation_provider' THEN
      p_resource_type IN ('accommodation', 'restaurant', 'activity', 'trip')

    -- Artisan : activité + hébergement adjacent (maison d'hôte de l'atelier)
    WHEN p_operator_type = 'artisan' THEN
      p_resource_type IN ('activity', 'accommodation')

    -- Restaurant : restaurant uniquement
    WHEN p_operator_type = 'restaurant' THEN
      p_resource_type = 'restaurant'

    -- Agence de voyage : packages / trips uniquement
    WHEN p_operator_type = 'travel_agency' THEN
      p_resource_type = 'trip'

    ELSE FALSE
  END;
$$;

COMMENT ON FUNCTION can_operator_submit IS 'Matrice de cohérence métier : quel sous-type d''opérateur peut soumettre quel type de produit.';


-- =====================================================================
-- 3. RLS — Politiques opérateurs sur les tables produits
--    Un opérateur peut INSERT/UPDATE ses propres ressources si la matrice l'autorise
-- =====================================================================

-- --- ACCOMMODATIONS ---
DROP POLICY IF EXISTS accommodations_operator_insert ON accommodations;
CREATE POLICY accommodations_operator_insert ON accommodations FOR INSERT WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role = 'tourist_operator'
      AND kyc_status = 'approved'
      AND can_operator_submit(operator_type, 'accommodation')
  )
);

DROP POLICY IF EXISTS accommodations_operator_update ON accommodations;
CREATE POLICY accommodations_operator_update ON accommodations FOR UPDATE USING (
  created_by = auth.uid()
  AND status != 'published' -- Une fois publiée, modif via admin uniquement
)
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS accommodations_operator_read_own ON accommodations;
CREATE POLICY accommodations_operator_read_own ON accommodations FOR SELECT USING (
  created_by = auth.uid() OR status = 'published'
);


-- --- RESTAURANTS ---
DROP POLICY IF EXISTS restaurants_operator_insert ON restaurants;
CREATE POLICY restaurants_operator_insert ON restaurants FOR INSERT WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role = 'tourist_operator'
      AND kyc_status = 'approved'
      AND can_operator_submit(operator_type, 'restaurant')
  )
);

DROP POLICY IF EXISTS restaurants_operator_update ON restaurants;
CREATE POLICY restaurants_operator_update ON restaurants FOR UPDATE USING (
  created_by = auth.uid()
  AND status != 'published'
)
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS restaurants_operator_read_own ON restaurants;
CREATE POLICY restaurants_operator_read_own ON restaurants FOR SELECT USING (
  created_by = auth.uid() OR status = 'published'
);


-- --- ACTIVITIES ---
DROP POLICY IF EXISTS activities_operator_insert ON activities;
CREATE POLICY activities_operator_insert ON activities FOR INSERT WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role = 'tourist_operator'
      AND kyc_status = 'approved'
      AND can_operator_submit(operator_type, 'activity')
  )
);

DROP POLICY IF EXISTS activities_operator_update ON activities;
CREATE POLICY activities_operator_update ON activities FOR UPDATE USING (
  created_by = auth.uid()
  AND status != 'published'
)
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS activities_operator_read_own ON activities;
CREATE POLICY activities_operator_read_own ON activities FOR SELECT USING (
  created_by = auth.uid() OR status = 'published'
);


-- --- TRIPS (extension pour agences et hébergeurs) ---
-- Note : la policy trips_owner_write existante autorise déjà les profils à créer leurs trips.
-- On ajoute une garde sur la matrice pour les opérateurs.

DROP POLICY IF EXISTS trips_operator_check ON trips;
CREATE POLICY trips_operator_check ON trips FOR INSERT WITH CHECK (
  created_by = auth.uid()
  AND (
    -- Guide : autorisation existante
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('guide_senior', 'guide_junior'))
    OR
    -- Opérateur : matrice + KYC
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role = 'tourist_operator'
        AND kyc_status = 'approved'
        AND can_operator_submit(operator_type, 'trip')
    )
  )
);


-- =====================================================================
-- 4. POLICY MEMORIES — rattachement opérateur lisible par tous
-- =====================================================================

-- Lecture publique des memories publiées (existant, on ne change pas)
-- Mais on s'assure que les related_* FK sont accessibles dans la requête

-- (Pas besoin de RLS spécifique : les FK pointent juste, et les tables référencées
--  ont déjà leurs propres policies de lecture.)


-- =====================================================================
-- 5. HELPER — Trouver tous les souvenirs liés à un opérateur
--    Utilisé par OperatorProfilePage.vue pour afficher la section souvenirs
-- =====================================================================

CREATE OR REPLACE FUNCTION get_operator_memories(p_operator_id UUID, p_limit INT DEFAULT 20)
RETURNS TABLE (
  id UUID,
  quote TEXT,
  photo_url TEXT,
  author_name TEXT,
  created_at TIMESTAMPTZ,
  related_type TEXT  -- 'direct', 'via_activity', 'via_accommodation', 'via_restaurant'
)
LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    m.id, m.quote, m.photo_url, p.display_name AS author_name, m.created_at,
    CASE
      WHEN m.related_operator_id = p_operator_id THEN 'direct'
      WHEN m.related_activity_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM activities a WHERE a.id = m.related_activity_id AND a.created_by = p_operator_id
      ) THEN 'via_activity'
      WHEN m.related_accommodation_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM accommodations ac WHERE ac.id = m.related_accommodation_id AND ac.created_by = p_operator_id
      ) THEN 'via_accommodation'
      WHEN m.related_restaurant_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM restaurants r WHERE r.id = m.related_restaurant_id AND r.created_by = p_operator_id
      ) THEN 'via_restaurant'
      ELSE 'other'
    END AS related_type
  FROM memories m
  JOIN profiles p ON p.id = m.author_id
  WHERE m.published = true
    AND (
      m.related_operator_id = p_operator_id
      OR EXISTS (SELECT 1 FROM activities WHERE id = m.related_activity_id AND created_by = p_operator_id)
      OR EXISTS (SELECT 1 FROM accommodations WHERE id = m.related_accommodation_id AND created_by = p_operator_id)
      OR EXISTS (SELECT 1 FROM restaurants WHERE id = m.related_restaurant_id AND created_by = p_operator_id)
    )
  ORDER BY m.created_at DESC
  LIMIT p_limit;
$$;

COMMENT ON FUNCTION get_operator_memories IS 'Récupère tous les souvenirs liés à un opérateur — directement OU via ses produits (activity, accommodation, restaurant).';
