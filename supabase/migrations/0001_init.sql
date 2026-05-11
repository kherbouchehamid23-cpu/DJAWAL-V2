-- =========================================================
-- DJAWAL V2 — Migration initiale
-- Sprint 1 : 12 tables principales, extensions, RLS, triggers
-- =========================================================

-- ===== EXTENSIONS =====
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ===== TYPES ÉNUMÉRÉS =====
CREATE TYPE app_role AS ENUM ('super_admin', 'guide_senior', 'guide_junior', 'voyageur');
CREATE TYPE kyc_status AS ENUM ('not_required', 'pending', 'approved', 'rejected');
CREATE TYPE cultural_theme AS ENUM ('saharien', 'mauresque', 'aures');
CREATE TYPE trip_status AS ENUM ('draft', 'pending_review', 'published', 'rejected');
CREATE TYPE resource_type AS ENUM ('hotel', 'site', 'restaurant');

-- =========================================================
-- 1. PROFILES — étend auth.users
-- =========================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL DEFAULT 'voyageur',
  display_name TEXT NOT NULL,
  bio TEXT,
  region TEXT,
  avatar_url TEXT,
  kyc_status kyc_status NOT NULL DEFAULT 'not_required',
  kyc_reviewed_by UUID REFERENCES profiles(id),
  kyc_reviewed_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON profiles(role) WHERE is_active = true;

-- Trigger : crée un profile à l'inscription
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, role, kyc_status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::app_role, 'voyageur'),
    CASE
      WHEN (NEW.raw_user_meta_data->>'role')::TEXT IN ('guide_senior', 'guide_junior') THEN 'pending'::kyc_status
      ELSE 'not_required'::kyc_status
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =========================================================
-- 2. DESTINATIONS — villes/wilayas avec thème culturel
-- =========================================================
CREATE TABLE destinations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  name_ar TEXT,
  slug TEXT NOT NULL UNIQUE,
  wilaya TEXT NOT NULL,
  cultural_theme cultural_theme NOT NULL,
  description TEXT NOT NULL,
  hero_image_url TEXT,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_destinations_theme ON destinations(cultural_theme);
CREATE INDEX idx_destinations_coords ON destinations USING GIST(coordinates);
CREATE INDEX idx_destinations_embedding ON destinations USING hnsw (embedding vector_cosine_ops);

-- =========================================================
-- 3-5. RESSOURCES : HOTELS, SITES, RESTAURANTS
-- Trois tables avec structure quasi-identique
-- =========================================================
CREATE TABLE hotels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT NOT NULL,
  address TEXT,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  price_range_da INT4RANGE,
  star_rating SMALLINT CHECK (star_rating BETWEEN 1 AND 5),
  images TEXT[] DEFAULT '{}',
  panorama_360_url TEXT,
  amenities TEXT[] DEFAULT '{}',
  validated_by UUID REFERENCES profiles(id),
  validated_at TIMESTAMPTZ,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE sites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT NOT NULL,
  category TEXT, -- musée, monument, plage, montagne, oasis, médina, etc.
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  entry_fee_da INT,
  images TEXT[] DEFAULT '{}',
  panorama_360_url TEXT,
  best_season TEXT[], -- ['printemps','automne']
  validated_by UUID REFERENCES profiles(id),
  validated_at TIMESTAMPTZ,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE restaurants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT NOT NULL,
  cuisine TEXT[], -- ['algeroise','kabyle','mozabite','poisson']
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  price_range_da INT4RANGE,
  images TEXT[] DEFAULT '{}',
  panorama_360_url TEXT,
  signature_dishes TEXT[],
  validated_by UUID REFERENCES profiles(id),
  validated_at TIMESTAMPTZ,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index communs sur les 3 tables ressources
CREATE INDEX idx_hotels_destination ON hotels(destination_id) WHERE validated_at IS NOT NULL;
CREATE INDEX idx_hotels_coords ON hotels USING GIST(coordinates);
CREATE INDEX idx_hotels_embedding ON hotels USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_sites_destination ON sites(destination_id) WHERE validated_at IS NOT NULL;
CREATE INDEX idx_sites_coords ON sites USING GIST(coordinates);
CREATE INDEX idx_sites_embedding ON sites USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_restaurants_destination ON restaurants(destination_id) WHERE validated_at IS NOT NULL;
CREATE INDEX idx_restaurants_coords ON restaurants USING GIST(coordinates);
CREATE INDEX idx_restaurants_embedding ON restaurants USING hnsw (embedding vector_cosine_ops);

-- =========================================================
-- 6. TRIPS — parcours composés par les guides
-- =========================================================
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  title_ar TEXT,
  destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE RESTRICT,
  duration_days SMALLINT NOT NULL CHECK (duration_days BETWEEN 1 AND 30),
  price_da INT NOT NULL CHECK (price_da >= 0),
  description TEXT NOT NULL,
  cover_image_url TEXT,
  max_travelers SMALLINT NOT NULL DEFAULT 8,
  difficulty TEXT, -- 'facile','modere','difficile'
  tags TEXT[] DEFAULT '{}',
  status trip_status NOT NULL DEFAULT 'draft',
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  published_at TIMESTAMPTZ,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_status ON trips(status, published_at DESC);
CREATE INDEX idx_trips_destination ON trips(destination_id) WHERE status = 'published';
CREATE INDEX idx_trips_creator ON trips(created_by);
CREATE INDEX idx_trips_embedding ON trips USING hnsw (embedding vector_cosine_ops);

-- =========================================================
-- 7-8. TRIP_DAYS et TRIP_STEPS — découpage en journées
-- =========================================================
CREATE TABLE trip_days (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  day_number SMALLINT NOT NULL CHECK (day_number >= 1),
  theme TEXT,
  description TEXT,
  UNIQUE (trip_id, day_number)
);

CREATE INDEX idx_trip_days_trip ON trip_days(trip_id, day_number);

CREATE TABLE trip_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_day_id UUID NOT NULL REFERENCES trip_days(id) ON DELETE CASCADE,
  step_order SMALLINT NOT NULL,
  resource_type resource_type NOT NULL,
  resource_id UUID NOT NULL,
  note TEXT,
  duration_minutes INT,
  UNIQUE (trip_day_id, step_order)
);

CREATE INDEX idx_trip_steps_day ON trip_steps(trip_day_id, step_order);
CREATE INDEX idx_trip_steps_resource ON trip_steps(resource_type, resource_id);

-- =========================================================
-- 9. REVIEWS — avis voyageurs sur un trip
-- =========================================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (trip_id, created_by)
);

CREATE INDEX idx_reviews_trip ON reviews(trip_id);

-- =========================================================
-- 10. MEMORIES — récits / souvenirs de voyage
-- =========================================================
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
  destination_id UUID REFERENCES destinations(id) ON DELETE SET NULL,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  quote TEXT NOT NULL CHECK (length(quote) BETWEEN 30 AND 600),
  photo_url TEXT,
  published BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_memories_published ON memories(created_at DESC) WHERE published = true;

-- =========================================================
-- 11. FAVORITES — voyages sauvegardés par le voyageur
-- =========================================================
CREATE TABLE favorites (
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, trip_id)
);

-- =========================================================
-- 12. AI_CONVERSATIONS — logs RAG (qualité & audit)
-- =========================================================
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  user_query TEXT NOT NULL,
  retrieved_resource_ids UUID[] NOT NULL DEFAULT '{}',
  llm_response JSONB,
  validation_passed BOOLEAN,
  validation_notes TEXT,
  tokens_used INT,
  latency_ms INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_conv_user ON ai_conversations(user_id, created_at DESC);
CREATE INDEX idx_ai_conv_failed ON ai_conversations(created_at DESC) WHERE validation_passed = false;

-- =========================================================
-- ROW LEVEL SECURITY — activation et policies
-- =========================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Helper : récupère le rôle de l'utilisateur courant
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS app_role
LANGUAGE SQL STABLE SECURITY DEFINER
AS $$ SELECT role FROM profiles WHERE id = auth.uid() $$;

-- === PROFILES ===
CREATE POLICY profiles_self_read ON profiles FOR SELECT
  USING (id = auth.uid() OR current_user_role() = 'super_admin');
CREATE POLICY profiles_public_read ON profiles FOR SELECT
  USING (is_active = true AND role IN ('guide_senior', 'guide_junior'));
CREATE POLICY profiles_self_update ON profiles FOR UPDATE
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY profiles_admin_all ON profiles FOR ALL
  USING (current_user_role() = 'super_admin');

-- === DESTINATIONS (master data — lecture publique, écriture admin) ===
CREATE POLICY destinations_public_read ON destinations FOR SELECT USING (true);
CREATE POLICY destinations_admin_write ON destinations FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- === HOTELS / SITES / RESTAURANTS ===
CREATE POLICY hotels_public_read ON hotels FOR SELECT USING (validated_at IS NOT NULL);
CREATE POLICY hotels_admin_write ON hotels FOR ALL
  USING (current_user_role() = 'super_admin') WITH CHECK (current_user_role() = 'super_admin');

CREATE POLICY sites_public_read ON sites FOR SELECT USING (validated_at IS NOT NULL);
CREATE POLICY sites_admin_write ON sites FOR ALL
  USING (current_user_role() = 'super_admin') WITH CHECK (current_user_role() = 'super_admin');

CREATE POLICY restaurants_public_read ON restaurants FOR SELECT USING (validated_at IS NOT NULL);
CREATE POLICY restaurants_admin_write ON restaurants FOR ALL
  USING (current_user_role() = 'super_admin') WITH CHECK (current_user_role() = 'super_admin');

-- === TRIPS — cœur de la logique de rôles ===
CREATE POLICY trips_public_read ON trips FOR SELECT
  USING (status = 'published' OR created_by = auth.uid() OR current_user_role() = 'super_admin');

CREATE POLICY trips_owner_write ON trips FOR INSERT WITH CHECK (
  created_by = auth.uid() AND
  current_user_role() IN ('guide_senior', 'guide_junior', 'super_admin')
);
CREATE POLICY trips_owner_update ON trips FOR UPDATE USING (created_by = auth.uid() AND status != 'published')
  WITH CHECK (created_by = auth.uid());
CREATE POLICY trips_admin_all ON trips FOR ALL USING (current_user_role() = 'super_admin');

-- Trigger : forcer status pour les guides
CREATE OR REPLACE FUNCTION enforce_trip_status_by_role()
RETURNS TRIGGER AS $$
BEGIN
  -- À l'INSERT, un guide_junior ne peut pas publier directement
  IF TG_OP = 'INSERT' THEN
    IF current_user_role() = 'guide_junior' AND NEW.status = 'published' THEN
      NEW.status := 'pending_review';
    END IF;
    -- guide_senior peut auto-publier
    IF current_user_role() = 'guide_senior' AND NEW.status = 'published' THEN
      NEW.published_at := NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trip_status_enforcement
  BEFORE INSERT OR UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION enforce_trip_status_by_role();

-- === TRIP_DAYS / TRIP_STEPS — héritent les permissions du trip parent ===
CREATE POLICY trip_days_read ON trip_days FOR SELECT USING (
  EXISTS (SELECT 1 FROM trips WHERE trips.id = trip_days.trip_id
          AND (trips.status = 'published' OR trips.created_by = auth.uid() OR current_user_role() = 'super_admin'))
);
CREATE POLICY trip_days_write ON trip_days FOR ALL USING (
  EXISTS (SELECT 1 FROM trips WHERE trips.id = trip_days.trip_id
          AND (trips.created_by = auth.uid() OR current_user_role() = 'super_admin'))
);

CREATE POLICY trip_steps_read ON trip_steps FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM trip_days td JOIN trips t ON t.id = td.trip_id
    WHERE td.id = trip_steps.trip_day_id
      AND (t.status = 'published' OR t.created_by = auth.uid() OR current_user_role() = 'super_admin')
  )
);
CREATE POLICY trip_steps_write ON trip_steps FOR ALL USING (
  EXISTS (
    SELECT 1 FROM trip_days td JOIN trips t ON t.id = td.trip_id
    WHERE td.id = trip_steps.trip_day_id
      AND (t.created_by = auth.uid() OR current_user_role() = 'super_admin')
  )
);

-- === REVIEWS — voyageurs commentent les trips publiés ===
CREATE POLICY reviews_public_read ON reviews FOR SELECT USING (true);
CREATE POLICY reviews_voyageur_insert ON reviews FOR INSERT WITH CHECK (
  created_by = auth.uid() AND
  EXISTS (SELECT 1 FROM trips WHERE id = trip_id AND status = 'published')
);
CREATE POLICY reviews_self_update ON reviews FOR UPDATE USING (created_by = auth.uid());
CREATE POLICY reviews_admin_delete ON reviews FOR DELETE USING (current_user_role() = 'super_admin' OR created_by = auth.uid());

-- === MEMORIES ===
CREATE POLICY memories_public_read ON memories FOR SELECT USING (published = true OR author_id = auth.uid());
CREATE POLICY memories_owner_write ON memories FOR ALL USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

-- === FAVORITES ===
CREATE POLICY favorites_self ON favorites FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- === AI_CONVERSATIONS ===
CREATE POLICY ai_conv_self_read ON ai_conversations FOR SELECT
  USING (user_id = auth.uid() OR current_user_role() = 'super_admin');
CREATE POLICY ai_conv_insert ON ai_conversations FOR INSERT WITH CHECK (true);

-- =========================================================
-- TRIGGERS UPDATED_AT
-- =========================================================
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_destinations_updated BEFORE UPDATE ON destinations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER tr_hotels_updated BEFORE UPDATE ON hotels FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER tr_sites_updated BEFORE UPDATE ON sites FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER tr_restaurants_updated BEFORE UPDATE ON restaurants FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER tr_trips_updated BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- COMMENTAIRES (utiles pour la doc auto)
-- =========================================================
COMMENT ON TABLE profiles IS 'Profil étendu des utilisateurs — un par auth.users';
COMMENT ON TABLE destinations IS 'Master data : villes/wilayas avec thème culturel pour le miroir dynamique';
COMMENT ON COLUMN destinations.cultural_theme IS 'Pilote la CSS frontend : saharien | mauresque | aures';
COMMENT ON COLUMN trips.embedding IS 'Vecteur 768d calculé via Gemini text-embedding-004, indexé HNSW pour le RAG';
COMMENT ON TABLE ai_conversations IS 'Logs du moteur RAG — audit qualité, détection hallucinations';
