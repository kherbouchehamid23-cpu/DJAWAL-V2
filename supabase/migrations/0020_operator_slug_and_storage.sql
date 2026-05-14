-- =========================================================
-- DJAWAL V2 — Sprint C : Slug auto + Storage buckets opérateur
-- =========================================================

-- =====================================================================
-- 1. FONCTION DE GÉNÉRATION DE SLUG
--    Convertit un nom commercial en slug URL-friendly
--    Ex : "Atelier de Saïda — Tapis Kabyles" → "atelier-de-saida-tapis-kabyles"
-- =====================================================================

CREATE OR REPLACE FUNCTION generate_slug(input_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  result TEXT;
BEGIN
  -- Conversion minuscules + retrait accents + remplacement non-alphanum par tirets
  result := lower(input_text);
  result := translate(result,
    'àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿœ',
    'aaaaaaaceeeeiiiinooooooouuuuyyoe'
  );
  result := regexp_replace(result, '[^a-z0-9]+', '-', 'g');
  result := regexp_replace(result, '^-+|-+$', '', 'g'); -- trim leading/trailing dashes
  RETURN result;
END;
$$;

COMMENT ON FUNCTION generate_slug IS 'Convertit une chaîne en slug URL-safe (lowercase, ASCII, tirets).';


-- =====================================================================
-- 2. FONCTION DE GÉNÉRATION UNIQUE DE SLUG SUR PROFILES
--    Ajoute un suffixe numérique si conflit
-- =====================================================================

CREATE OR REPLACE FUNCTION generate_unique_profile_slug(p_id UUID, p_base TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  candidate TEXT;
  base_slug TEXT;
  counter INT := 0;
BEGIN
  base_slug := generate_slug(p_base);
  IF base_slug IS NULL OR length(base_slug) = 0 THEN
    -- Fallback : utiliser les 8 premiers caractères de l'UUID
    base_slug := substr(replace(p_id::TEXT, '-', ''), 1, 8);
  END IF;
  candidate := base_slug;

  -- Boucle anti-conflit (max 100 tentatives)
  WHILE EXISTS (SELECT 1 FROM profiles WHERE slug = candidate AND id != p_id) LOOP
    counter := counter + 1;
    candidate := base_slug || '-' || counter;
    IF counter > 100 THEN
      candidate := base_slug || '-' || substr(replace(p_id::TEXT, '-', ''), 1, 6);
      EXIT;
    END IF;
  END LOOP;

  RETURN candidate;
END;
$$;

COMMENT ON FUNCTION generate_unique_profile_slug IS 'Génère un slug unique pour un profile, en ajoutant un suffixe en cas de conflit.';


-- =====================================================================
-- 3. TRIGGER : auto-générer le slug si non fourni
--    Source du slug : company_name si défini, sinon display_name
-- =====================================================================

CREATE OR REPLACE FUNCTION profiles_auto_slug()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  source_name TEXT;
BEGIN
  -- Ne génère que si slug est vide
  IF NEW.slug IS NULL OR length(trim(NEW.slug)) = 0 THEN
    source_name := COALESCE(NEW.company_name, NEW.display_name);
    IF source_name IS NOT NULL AND length(trim(source_name)) > 0 THEN
      NEW.slug := generate_unique_profile_slug(NEW.id, source_name);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_profiles_auto_slug ON profiles;
CREATE TRIGGER tr_profiles_auto_slug
  BEFORE INSERT OR UPDATE OF company_name, display_name, slug ON profiles
  FOR EACH ROW EXECUTE FUNCTION profiles_auto_slug();

COMMENT ON TRIGGER tr_profiles_auto_slug ON profiles IS 'Génère automatiquement un slug unique si non fourni.';


-- =====================================================================
-- 4. BACKFILL : générer le slug pour les profils existants qui n'en ont pas
-- =====================================================================

UPDATE profiles
SET slug = generate_unique_profile_slug(id, COALESCE(company_name, display_name))
WHERE slug IS NULL AND (company_name IS NOT NULL OR display_name IS NOT NULL);


-- =====================================================================
-- 5. STORAGE BUCKETS — operator-gallery + operator-avatars
-- =====================================================================

-- Bucket public pour les avatars opérateur (logo / photo de profil)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'operator-avatars',
  'operator-avatars',
  true,
  5242880, -- 5 Mo
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Bucket public pour les galeries opérateur (photos vitrine)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'operator-gallery',
  'operator-gallery',
  true,
  10485760, -- 10 Mo
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;


-- =====================================================================
-- 6. STORAGE RLS — Politiques d'accès
-- =====================================================================

-- Avatars : lecture publique, écriture par le propriétaire (premier segment = user_id)
DROP POLICY IF EXISTS operator_avatars_select ON storage.objects;
CREATE POLICY operator_avatars_select ON storage.objects
  FOR SELECT USING (bucket_id = 'operator-avatars');

DROP POLICY IF EXISTS operator_avatars_insert ON storage.objects;
CREATE POLICY operator_avatars_insert ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'operator-avatars'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS operator_avatars_update ON storage.objects;
CREATE POLICY operator_avatars_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'operator-avatars'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS operator_avatars_delete ON storage.objects;
CREATE POLICY operator_avatars_delete ON storage.objects
  FOR DELETE USING (
    bucket_id = 'operator-avatars'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

-- Galerie : mêmes règles
DROP POLICY IF EXISTS operator_gallery_select ON storage.objects;
CREATE POLICY operator_gallery_select ON storage.objects
  FOR SELECT USING (bucket_id = 'operator-gallery');

DROP POLICY IF EXISTS operator_gallery_insert ON storage.objects;
CREATE POLICY operator_gallery_insert ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'operator-gallery'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS operator_gallery_update ON storage.objects;
CREATE POLICY operator_gallery_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'operator-gallery'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS operator_gallery_delete ON storage.objects;
CREATE POLICY operator_gallery_delete ON storage.objects
  FOR DELETE USING (
    bucket_id = 'operator-gallery'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );


-- =====================================================================
-- 7. POLITIQUE PROFILE UPDATE : autoriser l'utilisateur à modifier son propre profil
--    (peut être déjà existante, on s'assure)
-- =====================================================================

DROP POLICY IF EXISTS profile_self_update ON profiles;
CREATE POLICY profile_self_update ON profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
