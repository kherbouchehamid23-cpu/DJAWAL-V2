-- =========================================================
-- DJAWAL V2 — Sprint A : Catégorie Hébergements — Partie 1
-- Création des enums uniquement (transaction courte)
-- =========================================================
-- Cette migration doit être committée AVANT la 0015 qui utilise
-- la nouvelle valeur 'accommodation' de l'enum resource_type.
-- PostgreSQL n'autorise pas l'usage d'une enum value dans la même
-- transaction où elle est ajoutée (erreur 55P04).
-- =========================================================

-- Enum des sous-types d'hébergement
CREATE TYPE accommodation_type AS ENUM (
  'hotel',           -- Hôtel classique (1-5 étoiles)
  'gite',            -- Gîte rural / familial
  'maison_hote',     -- Maison d'hôte / B&B
  'auberge_jeunesse',-- Auberge de jeunesse
  'lodge',           -- Lodge / camp saharien fixe
  'riad',            -- Riad / dar traditionnelle
  'kasbah_stay',     -- Séjour en kasbah rénovée
  'camping',         -- Camping (avec ou sans tente)
  'eco_lodge',       -- Eco-lodge / hébergement durable
  'refuge_montagne'  -- Refuge de montagne (Djurdjura, Aurès)
);

COMMENT ON TYPE accommodation_type IS 'Sous-catégories d''hébergements touristiques algériens';

-- Extension de l'enum resource_type
-- La valeur 'hotel' reste pour ne pas casser l'enum existant
-- (elle ne sera plus émise par le code côté SQL ni TypeScript).
ALTER TYPE resource_type ADD VALUE IF NOT EXISTS 'accommodation';
