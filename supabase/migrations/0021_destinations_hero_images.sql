-- =========================================================
-- DJAWAL V2 — Sprint D : Photos hero pour les destinations
-- =========================================================
-- ⚠️ MIGRATION NEUTRALISÉE
--
-- Cette migration tentait d'attribuer des photos Unsplash aux 23
-- destinations en fonction du cultural_theme. Mais ces photos sont
-- génériques (Maroc, Tunisie, Sahara non identifié) et ne reflètent
-- PAS les vraies wilayas algériennes.
--
-- Décision (Hamid, mai 2026) : mieux vaut afficher RIEN qu'une fausse
-- photo. Le fallback gradient + pattern berbère codé en QW4 prend le
-- relais et reste élégant.
--
-- Voir 0022_remove_misleading_destination_photos.sql pour le UPDATE
-- qui retire les URLs trompeuses si la migration avait déjà tourné.
-- =========================================================

SELECT 1;
