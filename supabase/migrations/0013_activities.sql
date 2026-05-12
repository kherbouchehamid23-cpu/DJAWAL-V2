-- =========================================================
-- DJAWAL V2 — Nouvelle catégorie : ACTIVITÉS TOURISTIQUES
-- Excursions, trek, plongée, ateliers artisanat, balades, etc.
-- =========================================================

-- Étendre l'enum resource_type pour inclure 'activity'
ALTER TYPE resource_type ADD VALUE IF NOT EXISTS 'activity';

-- ===== Table activities =====
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT NOT NULL,
  activity_type TEXT, -- 'trek', 'plongee', 'artisanat', 'gastronomie', 'culture', '4x4', 'cheval', 'voile', 'photo', 'famille', etc.
  coordinates GEOGRAPHY(POINT, 4326),
  price_da INT CHECK (price_da >= 0),
  duration_hours NUMERIC(4,1) CHECK (duration_hours > 0),
  min_age SMALLINT CHECK (min_age >= 0 AND min_age <= 99),
  max_group_size SMALLINT CHECK (max_group_size > 0),
  difficulty TEXT CHECK (difficulty IN ('facile','modere','difficile','expert')),
  best_season TEXT[] DEFAULT '{}',
  images TEXT[] DEFAULT '{}',
  panorama_360_url TEXT,
  virtual_tour_url TEXT,
  operator_name TEXT, -- Nom de l'opérateur/guide qui propose l'activité
  operator_phone TEXT,
  booking_required BOOLEAN NOT NULL DEFAULT true,
  validated_by UUID REFERENCES profiles(id),
  validated_at TIMESTAMPTZ,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activities_destination ON activities(destination_id) WHERE validated_at IS NOT NULL;
CREATE INDEX idx_activities_type ON activities(activity_type) WHERE validated_at IS NOT NULL;
CREATE INDEX idx_activities_coords ON activities USING GIST(coordinates);
CREATE INDEX idx_activities_embedding ON activities USING hnsw (embedding vector_cosine_ops);

-- RLS
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY activities_public_read ON activities FOR SELECT
  USING (validated_at IS NOT NULL);

CREATE POLICY activities_admin_write ON activities FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- Trigger updated_at
CREATE TRIGGER tr_activities_updated BEFORE UPDATE ON activities
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ===== Mise à jour match_resources pour inclure activities =====
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
  similarity FLOAT
)
LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  (SELECT 'hotel'::TEXT, h.id, h.name, h.description, h.destination_id, d.name,
          1 - (h.embedding <=> query_embedding)
   FROM hotels h JOIN destinations d ON d.id = h.destination_id
   WHERE h.embedding IS NOT NULL AND h.validated_at IS NOT NULL
     AND (destination_filter IS NULL OR h.destination_id = destination_filter)
   ORDER BY h.embedding <=> query_embedding LIMIT match_count)
  UNION ALL
  (SELECT 'site'::TEXT, s.id, s.name, s.description, s.destination_id, d.name,
          1 - (s.embedding <=> query_embedding)
   FROM sites s JOIN destinations d ON d.id = s.destination_id
   WHERE s.embedding IS NOT NULL AND s.validated_at IS NOT NULL
     AND (destination_filter IS NULL OR s.destination_id = destination_filter)
   ORDER BY s.embedding <=> query_embedding LIMIT match_count)
  UNION ALL
  (SELECT 'restaurant'::TEXT, r.id, r.name, r.description, r.destination_id, d.name,
          1 - (r.embedding <=> query_embedding)
   FROM restaurants r JOIN destinations d ON d.id = r.destination_id
   WHERE r.embedding IS NOT NULL AND r.validated_at IS NOT NULL
     AND (destination_filter IS NULL OR r.destination_id = destination_filter)
   ORDER BY r.embedding <=> query_embedding LIMIT match_count)
  UNION ALL
  (SELECT 'activity'::TEXT, a.id, a.name, a.description, a.destination_id, d.name,
          1 - (a.embedding <=> query_embedding)
   FROM activities a JOIN destinations d ON d.id = a.destination_id
   WHERE a.embedding IS NOT NULL AND a.validated_at IS NOT NULL
     AND (destination_filter IS NULL OR a.destination_id = destination_filter)
   ORDER BY a.embedding <=> query_embedding LIMIT match_count)
  ORDER BY 7 DESC LIMIT match_count;
$$;

COMMENT ON TABLE activities IS 'Activités touristiques (excursions, trek, ateliers, etc.) — gérées par admin';
