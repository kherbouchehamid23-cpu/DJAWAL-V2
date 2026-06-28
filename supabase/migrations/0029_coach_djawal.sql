-- =========================================================
-- DJAWAL V2 — Coach Djawal : schéma de support
-- 1) Champs multilingues obligatoires + qualité sur trips
-- 2) Table de réglages app_settings (seuil de publication configurable)
-- 3) Gate de publication doublé côté base (trigger)
-- Idempotent.
-- =========================================================

-- ===== 1. Colonnes trips =====
ALTER TABLE trips ADD COLUMN IF NOT EXISTS title_fr TEXT;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS title_en TEXT;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS description_fr TEXT;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS description_en TEXT;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS ai_quality_score INT DEFAULT 0;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS ai_assisted BOOLEAN DEFAULT false;
-- title_ar / description (FR historique) existent déjà ; on backfille les nouveaux champs
UPDATE trips SET title_fr = COALESCE(title_fr, title) WHERE title_fr IS NULL;
UPDATE trips SET description_fr = COALESCE(description_fr, description) WHERE description_fr IS NULL;

-- ===== 2. Réglages applicatifs (clé/valeur) =====
CREATE TABLE IF NOT EXISTS app_settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO app_settings (key, value) VALUES ('publish_quality_threshold', '70')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "app_settings_read" ON app_settings;
CREATE POLICY "app_settings_read" ON app_settings FOR SELECT USING (true);
DROP POLICY IF EXISTS "app_settings_write_admin" ON app_settings;
CREATE POLICY "app_settings_write_admin" ON app_settings FOR ALL
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

-- ===== 3. Gate de publication (trigger) =====
-- Refuse status='published' si : un triplet FR/AR/EN est vide,
-- pas d'image, prix/durée invalides, ou score < seuil configuré.
CREATE OR REPLACE FUNCTION public.enforce_trip_publish_quality()
RETURNS TRIGGER AS $$
DECLARE
  thr INT;
BEGIN
  IF NEW.status = 'published' THEN
    SELECT COALESCE((SELECT value::INT FROM app_settings WHERE key = 'publish_quality_threshold'), 70) INTO thr;

    IF COALESCE(NULLIF(TRIM(NEW.title_fr), ''), NULLIF(TRIM(NEW.title), '')) IS NULL
       OR NULLIF(TRIM(NEW.title_ar), '') IS NULL
       OR NULLIF(TRIM(NEW.title_en), '') IS NULL
       OR COALESCE(NULLIF(TRIM(NEW.description_fr), ''), NULLIF(TRIM(NEW.description), '')) IS NULL
       OR NULLIF(TRIM(NEW.description_ar), '') IS NULL
       OR NULLIF(TRIM(NEW.description_en), '') IS NULL THEN
      RAISE EXCEPTION 'Publication refusée : contenu trilingue FR+AR+EN obligatoire (titre & description).';
    END IF;

    IF NULLIF(TRIM(COALESCE(NEW.cover_image_url, '')), '') IS NULL THEN
      RAISE EXCEPTION 'Publication refusée : image de couverture obligatoire.';
    END IF;

    IF COALESCE(NEW.price_da, 0) <= 0 OR COALESCE(NEW.duration_days, 0) < 1 THEN
      RAISE EXCEPTION 'Publication refusée : prix et durée doivent être valides.';
    END IF;

    IF COALESCE(NEW.ai_quality_score, 0) < thr THEN
      RAISE EXCEPTION 'Publication refusée : score qualité % < seuil %.', COALESCE(NEW.ai_quality_score,0), thr;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_trip_publish_quality ON trips;
CREATE TRIGGER trg_trip_publish_quality
  BEFORE INSERT OR UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION public.enforce_trip_publish_quality();

-- Note : ce trigger s'exécute AVANT le trigger existant qui bascule les
-- guides_junior en 'pending_review'. L'ordre alphabétique des noms de triggers
-- garantit que la qualité est vérifiée d'abord.
