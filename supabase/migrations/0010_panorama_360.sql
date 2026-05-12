-- =========================================================
-- DJAWAL V2 — Ajout du champ virtual_tour_url
-- En complément de panorama_360_url qui sert pour images equirectangulaires
-- =========================================================

ALTER TABLE hotels ADD COLUMN IF NOT EXISTS virtual_tour_url TEXT;
ALTER TABLE sites ADD COLUMN IF NOT EXISTS virtual_tour_url TEXT;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS virtual_tour_url TEXT;

COMMENT ON COLUMN hotels.panorama_360_url IS 'URL d''une image equirectangulaire 360° (.jpg/.webp)';
COMMENT ON COLUMN hotels.virtual_tour_url IS 'URL d''une visite virtuelle externe (tour HTML, Matterport, etc.)';
COMMENT ON COLUMN sites.panorama_360_url IS 'URL d''une image equirectangulaire 360° (.jpg/.webp)';
COMMENT ON COLUMN sites.virtual_tour_url IS 'URL d''une visite virtuelle externe (tour HTML, Matterport, etc.)';
COMMENT ON COLUMN restaurants.panorama_360_url IS 'URL d''une image equirectangulaire 360° (.jpg/.webp)';
COMMENT ON COLUMN restaurants.virtual_tour_url IS 'URL d''une visite virtuelle externe (tour HTML, Matterport, etc.)';
