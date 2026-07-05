-- ============================================================================
-- Migration 0030 — Visites virtuelles (virtual tours)
-- ----------------------------------------------------------------------------
-- Une visite virtuelle = un ensemble de scènes 360° reliées par des « flèches »
-- de navigation, avec des points d'info (œuvres). Le rendu se fait côté front
-- (Pannellum + VR Three.js). La visite se rattache de façon POLYMORPHE à
-- n'importe quel élément (site, restaurant, hôtel, hébergement, destination,
-- opérateur… et tout type futur) via (target_type, target_id), ou reste
-- autonome (target_type / target_id NULL) et accessible via son slug.
--
-- Contrôle d'accès : le super_admin crée des visites et peut ACCORDER le droit
-- de créer des visites à d'autres utilisateurs via profiles.can_create_virtual_tours.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Droit de création accordé par le super_admin
-- ----------------------------------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS can_create_virtual_tours BOOLEAN NOT NULL DEFAULT FALSE;

-- ----------------------------------------------------------------------------
-- 2. Table virtual_tours
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS virtual_tours (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title        TEXT NOT NULL,
  slug         TEXT UNIQUE NOT NULL,
  summary      TEXT,
  cover_url    TEXT,
  -- Configuration de la visite (scènes + hotspots), pilotée par le front.
  -- Schéma : { firstScene, scenes: [ { id, title, panorama, hotspots:[
  --   {type:'scene', yaw, pitch, target, label} |
  --   {type:'info',  yaw, pitch, title, desc}
  -- ] } ] }
  config       JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Rattachement polymorphe (nullable = visite autonome). Volontairement SANS
  -- contrainte d'énumération pour accepter tout type d'élément présent ou futur.
  target_type  TEXT,
  target_id    UUID,
  created_by   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS virtual_tours_target_idx
  ON virtual_tours (target_type, target_id)
  WHERE is_published = TRUE;

CREATE INDEX IF NOT EXISTS virtual_tours_owner_idx
  ON virtual_tours (created_by, created_at DESC);

CREATE INDEX IF NOT EXISTS virtual_tours_slug_idx
  ON virtual_tours (slug);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION set_virtual_tours_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_virtual_tours_updated_at ON virtual_tours;
CREATE TRIGGER trg_virtual_tours_updated_at
  BEFORE UPDATE ON virtual_tours
  FOR EACH ROW EXECUTE FUNCTION set_virtual_tours_updated_at();

-- ----------------------------------------------------------------------------
-- 3. RLS
-- ----------------------------------------------------------------------------
ALTER TABLE virtual_tours ENABLE ROW LEVEL SECURITY;

-- Lecture publique des visites publiées
CREATE POLICY virtual_tours_public_read ON virtual_tours
  FOR SELECT
  USING (is_published = TRUE);

-- Lecture par le créateur (même non publiée)
CREATE POLICY virtual_tours_own_read ON virtual_tours
  FOR SELECT
  USING (created_by = auth.uid());

-- Lecture admin (toutes)
CREATE POLICY virtual_tours_admin_read ON virtual_tours
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  );

-- Création : par le super_admin, OU par un utilisateur explicitement autorisé,
-- et uniquement pour lui-même (created_by = soi).
CREATE POLICY virtual_tours_insert ON virtual_tours
  FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND (p.role = 'super_admin' OR p.can_create_virtual_tours = TRUE)
    )
  );

-- Modification : par le créateur, OU le super_admin
CREATE POLICY virtual_tours_update ON virtual_tours
  FOR UPDATE
  USING (
    created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  )
  WITH CHECK (
    created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  );

-- Suppression : par le créateur, OU le super_admin
CREATE POLICY virtual_tours_delete ON virtual_tours
  FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  );

COMMIT;
