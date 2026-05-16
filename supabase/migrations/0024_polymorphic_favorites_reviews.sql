-- ============================================================================
-- Migration 0024 — Favoris + Avis polymorphiques
-- ----------------------------------------------------------------------------
-- Permet à un utilisateur de favoriser ET de noter tout type d'élément :
--   trip, destination, accommodation, site, restaurant, activity,
--   guide, operator, memory
--
-- Remplace les anciennes tables `favorites` (mono-type trip) et `reviews`
-- (mono-type trip) par `user_favorites` et `user_reviews` polymorphiques.
--
-- Ajoute un statut de modération pour les avis (pending / approved / rejected / flagged).
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. user_favorites — polymorphique
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_favorites (
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN (
    'trip', 'destination', 'accommodation', 'site',
    'restaurant', 'activity', 'guide', 'operator', 'memory'
  )),
  target_id   UUID NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS user_favorites_user_idx
  ON user_favorites (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS user_favorites_target_idx
  ON user_favorites (target_type, target_id);

-- Migrer les anciens favoris (trip uniquement)
INSERT INTO user_favorites (user_id, target_type, target_id, created_at)
SELECT user_id, 'trip', trip_id, created_at
FROM favorites
ON CONFLICT DO NOTHING;

-- Supprimer l'ancienne table mono-type
DROP TABLE IF EXISTS favorites;

-- RLS
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_favorites_self ON user_favorites
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 2. user_reviews — polymorphique + modération
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_reviews (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN (
    'trip', 'destination', 'accommodation', 'site',
    'restaurant', 'activity', 'guide', 'operator'
  )),
  target_id   UUID NOT NULL,
  rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  status      TEXT NOT NULL DEFAULT 'approved'
              CHECK (status IN ('pending', 'approved', 'rejected', 'flagged')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  moderated_at TIMESTAMPTZ,
  moderated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  -- Un user ne peut laisser qu'un avis par élément
  UNIQUE (user_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS user_reviews_target_idx
  ON user_reviews (target_type, target_id, status);

CREATE INDEX IF NOT EXISTS user_reviews_user_idx
  ON user_reviews (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS user_reviews_pending_idx
  ON user_reviews (status, created_at DESC)
  WHERE status = 'pending';

-- Trigger updated_at automatique
CREATE OR REPLACE FUNCTION set_user_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_reviews_updated_at ON user_reviews;
CREATE TRIGGER trg_user_reviews_updated_at
  BEFORE UPDATE ON user_reviews
  FOR EACH ROW EXECUTE FUNCTION set_user_reviews_updated_at();

-- Migrer les anciens avis (trip uniquement, déjà approuvés par défaut puisque pas de modération avant)
INSERT INTO user_reviews (user_id, target_type, target_id, rating, comment, status, created_at)
SELECT created_by, 'trip', trip_id, rating, comment, 'approved', created_at
FROM reviews
ON CONFLICT DO NOTHING;

-- Supprimer l'ancienne table
DROP TABLE IF EXISTS reviews;

-- RLS
ALTER TABLE user_reviews ENABLE ROW LEVEL SECURITY;

-- Lecture publique des avis approuvés (tout le monde voit les avis publiés)
CREATE POLICY user_reviews_public_read ON user_reviews
  FOR SELECT
  USING (status = 'approved');

-- Lecture par l'auteur lui-même (peu importe le statut — peut voir son avis en attente/rejeté)
CREATE POLICY user_reviews_own_read ON user_reviews
  FOR SELECT
  USING (user_id = auth.uid());

-- Lecture admin (pour modération)
CREATE POLICY user_reviews_admin_read ON user_reviews
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'super_admin'
    )
  );

-- Insertion par l'utilisateur (statut auto-approved pour l'instant — modération activable plus tard)
CREATE POLICY user_reviews_insert ON user_reviews
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND status IN ('approved', 'pending')
  );

-- Modification de son propre avis
CREATE POLICY user_reviews_self_update ON user_reviews
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Modération admin
CREATE POLICY user_reviews_admin_update ON user_reviews
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'super_admin'
    )
  );

-- Suppression : par l'auteur OU l'admin
CREATE POLICY user_reviews_delete ON user_reviews
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'super_admin'
    )
  );

-- ============================================================================
-- 3. Vue agrégée — moyenne + distribution des notes par cible
-- ============================================================================
-- Utilisée par les pages pour afficher rapidement "⭐ 4.3 (12 avis)"

CREATE OR REPLACE VIEW review_aggregates AS
SELECT
  target_type,
  target_id,
  COUNT(*)                              AS review_count,
  ROUND(AVG(rating)::numeric, 2)        AS average_rating,
  COUNT(*) FILTER (WHERE rating = 5)    AS count_5,
  COUNT(*) FILTER (WHERE rating = 4)    AS count_4,
  COUNT(*) FILTER (WHERE rating = 3)    AS count_3,
  COUNT(*) FILTER (WHERE rating = 2)    AS count_2,
  COUNT(*) FILTER (WHERE rating = 1)    AS count_1
FROM user_reviews
WHERE status = 'approved'
GROUP BY target_type, target_id;

GRANT SELECT ON review_aggregates TO authenticated, anon;

COMMIT;
