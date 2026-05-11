# CLAUDE.md — Briefing pour Claude Code / Cowork

> Ce fichier est lu automatiquement par Claude Code et Cowork au démarrage de chaque session. Il contient le contexte projet, les conventions, et les pointeurs utiles.

## 1. Projet

**Djawal V2** (`جوّال`) — plateforme touristique algérienne biface (Voyageurs ↔ Guides) avec :
- Moteur IA RAG anti-hallucination (Gemini + pgvector)
- Constructeur de parcours drag-and-drop pour les guides
- Visites 360° en WebGL (Pannellum)
- Miroir culturel dynamique (3 thèmes : Saharien, Mauresque, Aurès)
- PWA installable mobile + desktop
- 3 rôles : Super Admin, Guide (Senior/Junior), Voyageur

Spec fonctionnelle complète : `../Spécifications Fonctionnelles - Projet Djawal V2.docx`
Architecture technique : `../architecture-djawal-v2.md` et `../architecture-diagram.html`

## 2. Stack technique

| Couche | Choix | Pourquoi |
|---|---|---|
| Frontend | Vue 3 + Vuetify 3 + Vite | Cohérent avec djawal.com actuel |
| PWA | `vite-plugin-pwa` (Workbox) | Mode offline + installable |
| State | Pinia | Standard Vue 3 |
| Router | Vue Router 4 | SPA navigation |
| Drag-drop | `vuedraggable@next` | Constructeur de parcours |
| Carte | Leaflet + OpenStreetMap | Gratuit, sans clé |
| 360° | Pannellum | WebGL open source |
| Audio | Howler.js | Ambiance sonore |
| Backend | Supabase | Auth + DB + Storage + Edge + Realtime |
| DB | PostgreSQL 15 + pgvector + PostGIS | Vector search + géolocalisation |
| LLM | Gemini 2.0 Flash (Groq Llama fallback) | Free tier généreux |
| Embeddings | text-embedding-004 (Google) | 768d multilingue |
| Hébergement | Vercel + Cloudflare DNS | Free tier, CI/CD natif |
| CI | GitHub Actions | Lint + tests sur PR |
| Monitoring | Sentry + Umami | Erreurs + analytics RGPD |
| Emails | Resend | Transactionnel |

## 3. Conventions de code

**Langage** : tout le code en **TypeScript** quand possible (composants Vue en `<script setup lang="ts">`). Le JS pur est toléré pour les configs.

**Composants Vue** : un fichier `.vue` par composant, nommé en PascalCase. Structure :
```vue
<script setup lang="ts">
// imports, props, refs, computed, methods
</script>
<template>
  <!-- markup -->
</template>
<style scoped>
  /* CSS scopé au composant */
</style>
```

**Naming** : `composables/use*.ts`, `stores/useXxxStore.ts`, `lib/*.ts`, `pages/*Page.vue`, `components/Pascal.vue`.

**Imports** : alias `@` pointe vers `src/` (configuré dans `vite.config.ts`).

**CSS** : variables CSS racine pour le design system (`--bleu-casbah`, `--or-sahara`, etc.). Trois thèmes culturels surchargent ces variables. Voir `src/styles/themes/`.

**i18n** : préparer pour FR (primaire) et AR (arabe) via `vue-i18n` à partir du Sprint 4.

## 4. Roles & RLS

Quatre rôles dans `profiles.role` :
- `super_admin` : tout accès
- `guide_senior` : publie directement, parcours auto-validés
- `guide_junior` : soumet en `pending_review`, validation manuelle requise
- `voyageur` : lecture publique, sauvegarde favoris

Tout est appliqué par Row Level Security PostgreSQL — voir `supabase/migrations/0001_init.sql`. **Ne jamais bypasser RLS côté client.**

## 5. Sprint en cours

**Sprint 1 — Fondations** ✅
- Repo Git + scaffolding Vue+Vite+Vuetify
- Migrations SQL initiales (12 tables)
- Design system avec 3 thèmes culturels
- Placeholder home + footer
- CI GitHub Actions
- Config Vercel + .env.example

**Sprint 2 — Auth & rôles + KYC** ✅ (ce sprint)
- Migration `0002_storage_kyc.sql` : buckets + policies + table `kyc_documents`
- Store Pinia auth complet (signin, signup, OAuth Google, magic link, reset password)
- Router guards (requiresAuth + requiresRole)
- Pages auth : Login, Signup (avec choix de rôle), Callback OAuth, ConfirmEmail, ResetPassword
- Composant `AuthCard` avec layout split-view culturel
- Page `MyAccountPage` pour les voyageurs
- Page `GuideDashboardPage` + `KycPage` pour les guides
- Dashboard `AdminDashboardPage` + `KycValidationPage` pour le Super Admin
- Initialisation auth au démarrage dans `main.ts`

**Sprint 3 — Master Data** (suivant)
- CRUD destinations / hotels / sites / restaurants
- Upload images via Supabase Storage
- Géocodage automatique via Nominatim
- Triggers pour calculer les embeddings
- Seed initial ~50 ressources

## 6. Commandes utiles

```bash
# Développement
npm install
npm run dev              # http://localhost:5173

# Supabase local (Docker requis)
npx supabase start
npx supabase db reset    # rejoue les migrations
npx supabase functions serve plan-trip --env-file .env.local

# Build & tests
npm run build
npm run preview
npm run lint
npm run typecheck

# Déploiement
vercel                    # preview
vercel --prod             # production

# Supabase production
npx supabase link --project-ref <ref>
npx supabase db push      # applique les migrations en prod
npx supabase functions deploy plan-trip
```

## 7. Variables d'environnement

Voir `.env.example` pour la liste complète. Les variables `VITE_*` sont exposées côté client ; les autres restent côté serveur (Edge Functions).

**Jamais commiter `.env.local`.** Toujours utiliser Vercel env vars en production.

## 8. Points de vigilance

- **Sécurité IA** : la clé Gemini doit **toujours** rester côté Edge Function, jamais exposée côté client.
- **RLS** : tester chaque nouvelle policy avec les 4 rôles avant de la merger.
- **Performance** : viser Lighthouse ≥ 90 sur les 4 axes. Lazy-load les routes lourdes.
- **Accessibilité** : WCAG AA minimum (contraste 4.5:1, navigation clavier, alt sur images).
- **Mobile-first** : tester d'abord en 375px, puis remonter.

## 9. Quand bloqué

- Spec fonctionnelle : `../Spécifications Fonctionnelles - Projet Djawal V2.docx`
- Architecture : `../architecture-djawal-v2.md`
- Maquettes design : `../proposition-1-landing-premium.html`, `../proposition-2-discovery-splitview.html`, `../proposition-3-cachet-culturel.html`
- Schéma visuel : `../architecture-diagram.html`

Demander à l'utilisateur les décisions produit / design / scope qui ne sont pas tranchées.
