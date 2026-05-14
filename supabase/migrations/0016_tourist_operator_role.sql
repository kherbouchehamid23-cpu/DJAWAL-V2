-- =========================================================
-- DJAWAL V2 — Sprint B : Opérateurs Touristiques — Partie 1
-- Ajout du rôle 'tourist_operator' à l'enum app_role
-- =========================================================
-- Cette migration doit être committée AVANT la 0017 qui utilise
-- la nouvelle valeur. PostgreSQL n'autorise pas l'usage d'une
-- enum value dans la même transaction où elle est ajoutée.
-- =========================================================

ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'tourist_operator';

COMMENT ON TYPE app_role IS 'Rôles applicatifs : voyageur, guide_junior, guide_senior, tourist_operator, super_admin';
