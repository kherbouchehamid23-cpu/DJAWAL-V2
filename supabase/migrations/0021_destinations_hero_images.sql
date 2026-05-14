-- =========================================================
-- DJAWAL V2 — Sprint D : Photos hero pour les destinations
-- =========================================================
-- Attribue des photos Unsplash libres de droits aux 23 destinations,
-- en fonction du cultural_theme (saharien / mauresque / aurès).
--
-- Source : photos Unsplash, licence Unsplash gratuite (commerciale OK,
-- pas d'attribution obligatoire mais recommandée).
--
-- Ces URLs sont des fallbacks temporaires — l'admin pourra remplacer
-- chaque destination par une photo locale via /admin/resources/...
-- ou en uploadant dans le bucket hero-images.
-- =========================================================

-- Wilayas saharien (désert, Tassili, Hoggar, dunes)
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1547499924-d2dbfaa9c4c8?w=1600&q=80' WHERE name IN ('Tamanrasset', 'Tassili n''Ajjer', 'Hoggar') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1600&q=80' WHERE name IN ('Adrar', 'Timimoun', 'Djanet') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1564415051543-ee0ed4ea2e3c?w=1600&q=80' WHERE name IN ('Ghardaïa', 'Béni Abbès', 'Ouargla', 'Illizi') AND hero_image_url IS NULL;

-- Wilayas mauresque (médina, casbah, méditerranée)
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1539020140153-e8c237425f57?w=1600&q=80' WHERE name IN ('Alger', 'Casbah d''Alger') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1565967511849-76a60a516170?w=1600&q=80' WHERE name IN ('Oran', 'Tipaza', 'Annaba') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1503525531019-c1cefb2b0c19?w=1600&q=80' WHERE name IN ('Tlemcen', 'Constantine', 'Dellys') AND hero_image_url IS NULL;

-- Wilayas aurès / kabylie (montagnes, vert, refuges)
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1600&q=80' WHERE name IN ('Béjaïa', 'Tizi Ouzou', 'Tikjda') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=1600&q=80' WHERE name IN ('Batna', 'Khenchela', 'Aurès') AND hero_image_url IS NULL;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1600&q=80' WHERE name IN ('Sétif', 'Bouira', 'Chréa') AND hero_image_url IS NULL;

-- Fallback générique par cultural_theme pour toute destination sans hero_image_url restante
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1547499924-d2dbfaa9c4c8?w=1600&q=80' WHERE hero_image_url IS NULL AND cultural_theme = 'saharien'::cultural_theme;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1539020140153-e8c237425f57?w=1600&q=80' WHERE hero_image_url IS NULL AND cultural_theme = 'mauresque'::cultural_theme;
UPDATE destinations SET hero_image_url = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1600&q=80' WHERE hero_image_url IS NULL AND cultural_theme = 'aures'::cultural_theme;
