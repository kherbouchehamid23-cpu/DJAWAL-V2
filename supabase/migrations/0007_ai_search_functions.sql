-- =========================================================
-- DJAWAL V2 — Sprint 7 : Fonctions de recherche sémantique
-- pgvector + HNSW déjà actifs (sprint 1)
-- Embeddings 768d via Gemini text-embedding-004
-- =========================================================

-- ===== Recherche sémantique cross-ressources =====
-- Renvoie les ressources (hotels + sites + restaurants) les plus proches
-- d'un embedding requête, optionnellement filtrées par destination.

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
LANGUAGE SQL STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  (
    SELECT 'hotel'::TEXT, h.id, h.name, h.description, h.destination_id, d.name,
           1 - (h.embedding <=> query_embedding) AS similarity
    FROM hotels h
    JOIN destinations d ON d.id = h.destination_id
    WHERE h.embedding IS NOT NULL
      AND h.validated_at IS NOT NULL
      AND (destination_filter IS NULL OR h.destination_id = destination_filter)
    ORDER BY h.embedding <=> query_embedding
    LIMIT match_count
  )
  UNION ALL
  (
    SELECT 'site'::TEXT, s.id, s.name, s.description, s.destination_id, d.name,
           1 - (s.embedding <=> query_embedding) AS similarity
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
           1 - (r.embedding <=> query_embedding) AS similarity
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

-- ===== Recherche sémantique destinations =====
CREATE OR REPLACE FUNCTION public.match_destinations(
  query_embedding VECTOR(768),
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  wilaya TEXT,
  cultural_theme TEXT,
  description TEXT,
  similarity FLOAT
)
LANGUAGE SQL STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT d.id, d.name, d.wilaya, d.cultural_theme::TEXT, d.description,
         1 - (d.embedding <=> query_embedding) AS similarity
  FROM destinations d
  WHERE d.embedding IS NOT NULL
  ORDER BY d.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- ===== Recherche sémantique parcours publiés =====
CREATE OR REPLACE FUNCTION public.match_trips(
  query_embedding VECTOR(768),
  match_count INT DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  duration_days SMALLINT,
  price_da INT,
  description TEXT,
  destination_id UUID,
  destination_name TEXT,
  similarity FLOAT
)
LANGUAGE SQL STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id, t.title, t.duration_days, t.price_da, t.description,
         t.destination_id, d.name,
         1 - (t.embedding <=> query_embedding) AS similarity
  FROM trips t
  JOIN destinations d ON d.id = t.destination_id
  WHERE t.embedding IS NOT NULL
    AND t.status = 'published'
  ORDER BY t.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- ===== Policy lecture ai_conversations pour le user lui-même =====
-- (déjà créée au sprint 1, on s'assure que insert anonyme passe)
DROP POLICY IF EXISTS ai_conv_insert ON ai_conversations;
CREATE POLICY ai_conv_insert ON ai_conversations FOR INSERT
  WITH CHECK (true);

COMMENT ON FUNCTION match_resources IS 'Recherche sémantique cross-ressources via embedding 768d Gemini';
COMMENT ON FUNCTION match_destinations IS 'Recherche sémantique destinations';
COMMENT ON FUNCTION match_trips IS 'Recherche sémantique parcours publiés';
