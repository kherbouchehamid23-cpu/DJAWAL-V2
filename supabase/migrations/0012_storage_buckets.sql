-- =========================================================
-- DJAWAL V2 — Buckets Storage pour uploads d'images
-- =========================================================

-- Créer les buckets s'ils n'existent pas (publics)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('trip-covers', 'trip-covers', true, 10485760, ARRAY['image/jpeg','image/png','image/webp','image/avif']),
  ('memory-photos', 'memory-photos', true, 10485760, ARRAY['image/jpeg','image/png','image/webp','image/avif'])
ON CONFLICT (id) DO NOTHING;

-- ===== Policies bucket trip-covers =====
-- Lecture publique
CREATE POLICY "trip_covers_public_read" ON storage.objects FOR SELECT
USING (bucket_id = 'trip-covers');

-- Upload : guides et admin uniquement
CREATE POLICY "trip_covers_guide_insert" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'trip-covers'
  AND auth.role() = 'authenticated'
  AND public.current_user_role() IN ('guide_senior','guide_junior','super_admin')
);

-- Delete : propre author ou admin
CREATE POLICY "trip_covers_owner_delete" ON storage.objects FOR DELETE
USING (
  bucket_id = 'trip-covers'
  AND (auth.uid() = owner OR public.current_user_role() = 'super_admin')
);

-- ===== Policies bucket memory-photos =====
CREATE POLICY "memory_photos_public_read" ON storage.objects FOR SELECT
USING (bucket_id = 'memory-photos');

-- Upload : tout utilisateur authentifié
CREATE POLICY "memory_photos_authenticated_insert" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'memory-photos'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "memory_photos_owner_delete" ON storage.objects FOR DELETE
USING (
  bucket_id = 'memory-photos'
  AND (auth.uid() = owner OR public.current_user_role() = 'super_admin')
);
