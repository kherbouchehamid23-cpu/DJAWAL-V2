-- =========================================================
-- DJAWAL V2 — Sprint D : Retrait des photos Unsplash trompeuses
-- =========================================================
-- Les URLs Unsplash injectées par 0021 sont des photos génériques
-- (Maroc, Tunisie, Sahara non identifié) qui ne reflètent PAS
-- les vraies wilayas algériennes (Tassili, Casbah d'Alger, Djurdjura...).
--
-- Plutôt que d'afficher des photos d'ailleurs présentées comme
-- algériennes (malhonnête vis-à-vis du voyageur), on retire tout.
--
-- Le fallback en place (gradient cultural_theme + pattern berbère
-- en losanges, codé dans TripsPage.vue / DestinationPage.vue) prend
-- alors le relais — c'est élégant et 100 % honnête.
--
-- Les vraies photos seront uploadées progressivement via :
--   - /admin/resources/destinations (upload manuel par l'admin)
--   - contributions photos des guides locaux (Sprint E à venir)
-- =========================================================

UPDATE destinations
SET hero_image_url = NULL
WHERE hero_image_url LIKE '%unsplash.com%';
