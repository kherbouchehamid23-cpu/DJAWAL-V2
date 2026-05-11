# Djawal V2 — جوّال

> Plateforme communautaire de tourisme algérien — voyages, hôtels, sites, restaurants, planificateur IA et visites 360°.

[![CI](https://github.com/djawal/djawal-v2/actions/workflows/ci.yml/badge.svg)](https://github.com/djawal/djawal-v2/actions)

## Stack

- **Frontend** : Vue 3 + Vuetify 3 + Vite + PWA
- **Backend** : Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **IA RAG** : Google Gemini 2.0 Flash + pgvector + grounded generation
- **Carte** : Leaflet + OpenStreetMap
- **360°** : Pannellum (WebGL)
- **Hébergement** : Vercel + Cloudflare DNS

Architecture complète : voir [`../architecture-djawal-v2.md`](../architecture-djawal-v2.md) et [`../architecture-diagram.html`](../architecture-diagram.html).

## Démarrage rapide

### Prérequis

- Node.js ≥ 20
- Docker (pour Supabase local — optionnel mais recommandé)
- Compte Supabase (gratuit) et Vercel (gratuit) pour le déploiement

### Installation

```bash
# Cloner
git clone <repo-url> djawal-v2 && cd djawal-v2

# Dépendances
npm install

# Variables d'environnement
cp .env.example .env.local
# Renseigner VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY

# Lancer Supabase local (optionnel)
npx supabase start
# → URL locale dispo dans la sortie de la commande
# → Studio : http://localhost:54323

# Appliquer les migrations
npx supabase db reset

# Démarrer l'app
npm run dev
# → http://localhost:5173
```

### Connexion à Supabase Cloud

```bash
npx supabase login
npx supabase link --project-ref <votre-ref>
npx supabase db push           # applique les migrations en cloud
```

## Commandes

| Commande | Description |
|---|---|
| `npm run dev` | Serveur de dev sur `:5173` avec HMR |
| `npm run build` | Build de production (sortie `dist/`) |
| `npm run preview` | Sert le build pour test local |
| `npm run lint` | ESLint avec auto-fix |
| `npm run typecheck` | Vérification TypeScript stricte |
| `npm test` | Tests unitaires Vitest |
| `npx supabase start` | Démarre Supabase local (Docker) |
| `npx supabase db reset` | Rejoue toutes les migrations |
| `npx supabase functions serve plan-trip` | Sert une edge function en local |

## Structure

```
djawal-v2/
├── public/                 Assets statiques (favicon, icons PWA, robots)
├── src/
│   ├── components/        Composants Vue réutilisables
│   ├── composables/       Hooks Vue (useCulturalTheme, etc.)
│   ├── lib/               Clients (supabase.ts, leaflet, etc.)
│   ├── pages/             Pages route-based (HomePage, TripsPage…)
│   ├── plugins/           Vuetify config
│   ├── router/            Vue Router 4
│   ├── stores/            Pinia (auth, theme)
│   ├── styles/            Design system + 3 thèmes culturels
│   ├── types/             Types TypeScript (synchro Supabase)
│   ├── App.vue            Layout racine
│   └── main.ts            Point d'entrée
├── supabase/
│   ├── migrations/        SQL versionné — 0001_init.sql
│   ├── functions/         Edge Functions Deno (Sprints 2+)
│   └── config.toml        Config locale
├── .github/workflows/     CI GitHub Actions
├── CLAUDE.md              Briefing pour Claude Code / Cowork
├── vite.config.ts         Build + PWA config
├── vercel.json            Hébergement Vercel
└── README.md
```

## Sprints

- ✅ **Sprint 1** — Fondations (cette release)
- ⏭ Sprint 2 — Auth & rôles + KYC
- ⏭ Sprint 3 — Master Data Manager
- ⏭ Sprint 4 — Vitrine voyageur publique
- ⏭ Sprint 5 — Constructeur de parcours
- ⏭ Sprint 6 — Moteur IA RAG
- ⏭ Sprint 7 — Visites 360° & ambiance sonore
- ⏭ Sprint 8 — PWA + mise en production

Voir le plan détaillé dans [`../architecture-djawal-v2.md`](../architecture-djawal-v2.md) section 12.

## Conventions

- TypeScript strict partout
- Composants Vue en `<script setup lang="ts">`
- Alias `@/` → `src/`
- CSS variables racine + 3 thèmes culturels
- RLS PostgreSQL pour toutes les permissions (jamais côté client)
- Conventional Commits pour les messages Git

## Sécurité

- Clés API LLM **uniquement** dans les Edge Functions, jamais côté client
- RLS activée sur toutes les tables
- MFA obligatoire pour Super Admin et Guides Senior
- KYC manuel des Guides à l'inscription
- Headers de sécurité dans `vercel.json`

## Licence

Propriétaire — © 2026 Djawal. Tous droits réservés.

---

Conçu en Algérie · صُنع في الجزائر 🇩🇿


<!-- Deployment trigger: 2026-05-11 -->
