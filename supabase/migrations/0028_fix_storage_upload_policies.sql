-- =========================================================
-- DJAWAL V2 — Fix RLS storage : uploads avatars & memory-photos
-- Erreur corrigée : "new row violates row-level security policy"
-- Recréation idempotente des policies (la 0012 a pu échouer
-- partiellement car elle n'utilisait pas DROP POLICY IF EXISTS).
-- =========================================================

-- ===== AVATARS — lecture publique, écriture sur son propre dossier {uid}/... =====
DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
CREATE POLICY "avatars_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_own_write" ON storage.objects;
CREATE POLICY "avatars_own_write" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "avatars_own_update" ON storage.objects;
CREATE POLICY "avatars_own_update" ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "avatars_own_delete" ON storage.objects;
CREATE POLICY "avatars_own_delete" ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ===== MEMORY-PHOTOS — lecture publique, upload pour tout utilisateur authentifié =====
DROP POLICY IF EXISTS "memory_photos_public_read" ON storage.objects;
CREATE POLICY "memory_photos_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'memory-photos');

DROP POLICY IF EXISTS "memory_photos_authenticated_insert" ON storage.objects;
CREATE POLICY "memory_photos_authenticated_insert" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'memory-photos'
    AND auth.role() = 'authenticated'
  );

DROP POLICY IF EXISTS "memory_photos_owner_delete" ON storage.objects;
CREATE POLICY "memory_photos_owner_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'memory-photos'
    AND (auth.uid() = owner OR public.current_user_role() = 'super_admin')
  );

-- ===== TRIP-COVERS — recréées aussi au cas où la 0012 a échoué avant de les poser =====
DROP POLICY IF EXISTS "trip_covers_public_read" ON storage.objects;
CREATE POLICY "trip_covers_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'trip-covers');

DROP POLICY IF EXISTS "trip_covers_guide_insert" ON storage.objects;
CREATE POLICY "trip_covers_guide_insert" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'trip-covers'
    AND auth.role() = 'authenticated'
    AND public.current_user_role() IN ('guide_senior','guide_junior','super_admin')
  );

DROP POLICY IF EXISTS "trip_covers_owner_delete" ON storage.objects;
CREATE POLICY "trip_covers_owner_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'trip-covers'
    AND (auth.uid() = owner OR public.current_user_role() = 'super_admin')
  );

-- ===== Buckets : s'assurer qu'ils existent (idempotent) =====
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('memory-photos', 'memory-photos', true, 26214400, ARRAY['image/jpeg','image/png','image/webp','image/avif']),
  ('avatars', 'avatars', true, 5242880, ARRAY['image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Si le bucket avatars existait déjà (créé à 2 Mo par la 0002),
-- aligner la limite et les types MIME sur ce qu'autorise le client (5 Mo).
UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/png','image/jpeg','image/webp','image/avif']
WHERE id = 'avatars';
