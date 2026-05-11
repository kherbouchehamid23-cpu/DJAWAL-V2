-- =========================================================
-- DJAWAL V2 — Sprint 2 : Storage buckets + KYC policies
-- =========================================================

-- ===== BUCKETS DE STOCKAGE =====
-- Note : les buckets définis dans supabase/config.toml sont créés lors du `supabase start` local,
-- mais en cloud il faut les créer via SQL ou Dashboard. On les crée ici idempotemment.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 2097152, ARRAY['image/png', 'image/jpeg', 'image/webp']),
  ('hero-images', 'hero-images', true, 10485760, ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/avif']),
  ('panoramas', 'panoramas', true, 31457280, ARRAY['image/jpeg']),
  ('kyc-documents', 'kyc-documents', false, 5242880, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('ambient-sounds', 'ambient-sounds', true, 512000, ARRAY['audio/opus', 'audio/ogg'])
ON CONFLICT (id) DO NOTHING;

-- ===== POLICIES STORAGE =====

-- AVATARS — lecture publique, écriture sur son propre dossier
CREATE POLICY "avatars_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');
CREATE POLICY "avatars_own_write" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatars_own_update" ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatars_own_delete" ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- HERO IMAGES & PANORAMAS — lecture publique, écriture Super Admin uniquement
CREATE POLICY "hero_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'hero-images');
CREATE POLICY "hero_admin_write" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'hero-images' AND current_user_role() = 'super_admin');

CREATE POLICY "panoramas_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'panoramas');
CREATE POLICY "panoramas_admin_write" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'panoramas' AND current_user_role() = 'super_admin');

CREATE POLICY "sounds_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'ambient-sounds');
CREATE POLICY "sounds_admin_write" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'ambient-sounds' AND current_user_role() = 'super_admin');

-- KYC DOCUMENTS — lecture restreinte (propriétaire + Super Admin), écriture par propriétaire
CREATE POLICY "kyc_owner_read" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc-documents'
    AND (auth.uid()::text = (storage.foldername(name))[1] OR current_user_role() = 'super_admin')
  );
CREATE POLICY "kyc_owner_write" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
CREATE POLICY "kyc_owner_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'kyc-documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
CREATE POLICY "kyc_admin_delete" ON storage.objects FOR DELETE
  USING (bucket_id = 'kyc-documents' AND current_user_role() = 'super_admin');

-- ===== TABLE KYC_DOCUMENTS — métadonnées des pièces uploadées =====
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('id_card_front', 'id_card_back', 'professional_card', 'selfie', 'other')),
  storage_path TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (profile_id, document_type)
);

CREATE INDEX idx_kyc_docs_profile ON kyc_documents(profile_id);

ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kyc_docs_self_read" ON kyc_documents FOR SELECT
  USING (profile_id = auth.uid() OR current_user_role() = 'super_admin');
CREATE POLICY "kyc_docs_self_write" ON kyc_documents FOR INSERT
  WITH CHECK (profile_id = auth.uid());
CREATE POLICY "kyc_docs_self_update" ON kyc_documents FOR UPDATE
  USING (profile_id = auth.uid());

-- ===== HELPER POUR SUPER ADMIN — première inscription =====
-- Permet de promouvoir manuellement le premier utilisateur en Super Admin via SQL :
-- UPDATE profiles SET role = 'super_admin' WHERE id = (SELECT id FROM auth.users WHERE email = 'votre-email@example.com');

COMMENT ON TABLE kyc_documents IS 'Métadonnées des documents KYC uploadés par les guides';
