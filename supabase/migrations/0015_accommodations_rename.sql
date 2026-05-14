-- =========================================================
-- DJAWAL V2 — Sprint A : Catégorie Hébergements — Partie 2
-- Renommage table, colonne, indexes, fonction match_resources, RLS
-- =========================================================
-- Prérequis : migration 0014 appliquée (les enums sont créés et committés)
-- =========================================================

-- ===== Renommage de la table =====
ALTER TABLE hotels RENAME TO accommodations;

-- Renommage des indexes (PostgreSQL ne le fait pas auto avec ALTER TABLE RENAME)
ALTER INDEX IF EXISTS hotels_pkey RENAME TO accommodations_pkey;
ALTER INDEX IF EXISTS idx_hotels_destination RENAME TO idx_accommodations_destination;
ALTER INDEX IF EXISTS idx_hotels_coordinates RENAME TO idx_accommodations_coordinates;
ALTER INDEX IF EXISTS idx_hotels_embedding RENAME TO idx_accommodations_embedding;

-- ===== Colonne accommodation_type =====
ALTER TABLE accommodations
  ADD COLUMN accommodation_type accommodation_type NOT NULL DEFAULT 'hotel';

CREATE INDEX idx_accommodations_type ON accommodations(accommodation_type);

COMMENT ON COLUMN accommodations.accommodation_type IS 'Sous-catégorie : hotel, gite, maison_hote, auberge_jeunesse, etc.';

-- ===== Migration data trip_steps =====
-- La valeur 'accommodation' est utilisable car committée dans la 0014
UPDATE trip_steps SET resource_type = 'accommodation' WHERE resource_type = 'hotel';

-- ===== Refonte de match_resources() =====
DROP FUNCTION IF EXISTS public.match_resources(VECTOR(768), INT, UUID);

CREATE OR REPLACE FUNCTION public.match_resources(
  query_embedding VECTOR(768),
  match_count INT DEFAULT 8,
  destination_filter UUID DEFAULT NULL
)
RETURNS TABLE (
  resource_type TEXT,
  resource_id UUID,
  name TEXT,
  description TEXT,
  destination_id UUID,
  destination_name TEXT,
  similarity FLOAT,
  accommodation_subtype TEXT
)
LANGUAGE SQL STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  (
    SELECT 'accommodation'::TEXT, a.id, a.name, a.description, a.destination_id, d.name,
           1 - (a.embedding <=> query_embedding) AS similarity,
           a.accommodation_type::TEXT
    FROM accommodations a
    JOIN destinations d ON d.id = a.destination_id
    WHERE a.embedding IS NOT NULL
      AND a.validated_at IS NOT NULL
      AND (destination_filter IS NULL OR a.destination_id = destination_filter)
    ORDER BY a.embedding <=> query_embedding
    LIMIT match_count
  )
  UNION ALL
  (
    SELECT 'site'::TEXT, s.id, s.name, s.description, s.destination_id, d.name,
           1 - (s.embedding <=> query_embedding) AS similarity,
           NULL::TEXT
    FROM sites s
    JOIN destinations d ON d.id = s.destination_id
    WHERE s.embedding IS NOT NULL
      AND s.validated_at IS NOT NULL
      AND (destination_filter IS NULL OR s.destination_id = destination_filter)
    ORDER BY s.embedding <=> query_embedding
    LIMIT match_count
  )
  UNION ALL
  (
    SELECT 'restaurant'::TEXT, r.id, r.name, r.description, r.destination_id, d.name,
           1 - (r.embedding <=> query_embedding) AS similarity,
           NULL::TEXT
    FROM restaurants r
    JOIN destinations d ON d.id = r.destination_id
    WHERE r.embedding IS NOT NULL
      AND r.validated_at IS NOT NULL
      AND (destination_filter IS NULL OR r.destination_id = destination_filter)
    ORDER BY r.embedding <=> query_embedding
    LIMIT match_count
  )
  ORDER BY similarity DESC
  LIMIT match_count;
$$;

COMMENT ON FUNCTION match_resources IS 'Recherche sémantique cross-ressources (accommodations + sites + restaurants) via embedding 768d.';

-- ===== RLS policies =====
DROP POLICY IF EXISTS hotels_select_public ON accommodations;
DROP POLICY IF EXISTS hotels_insert_admin ON accommodations;
DROP POLICY IF EXISTS hotels_update_admin ON accommodations;
DROP POLICY IF EXISTS hotels_delete_admin ON accommodations;

CREATE POLICY accommodations_select_public ON accommodations
  FOR SELECT USING (true);

CREATE POLICY accommodations_insert_admin ON accommodations
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY accommodations_update_admin ON accommodations
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY accommodations_delete_admin ON accommodations
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );
