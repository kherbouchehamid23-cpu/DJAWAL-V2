#!/usr/bin/env bash
# =========================================================
# DJAWAL V2 — Bootstrap automatique du Sprint 1
# Exécutable directement par Claude Code / Cowork
# =========================================================
set -e

echo "=========================================="
echo "  DJAWAL V2 — Bootstrap Sprint 1"
echo "=========================================="

# 1. Vérifier les prérequis
command -v node >/dev/null 2>&1 || { echo "❌ Node.js requis (≥ 20)"; exit 1; }
NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
  echo "❌ Node.js 20+ requis (actuel : v$NODE_VERSION)"
  exit 1
fi
echo "✓ Node.js $(node -v)"

# 2. Installer les dépendances
echo ""
echo "📦 Installation des dépendances…"
npm install

# 3. Copier .env si pas présent
if [ ! -f .env.local ]; then
  echo ""
  echo "📝 Création de .env.local depuis .env.example"
  cp .env.example .env.local
  echo "⚠️  Renseigner VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.local"
fi

# 4. Supabase local si Docker disponible
if command -v docker >/dev/null 2>&1; then
  echo ""
  echo "🐳 Docker détecté — démarrage de Supabase local…"
  npx supabase start || echo "⚠️  Supabase déjà démarré ou erreur — ignoré"
else
  echo ""
  echo "⚠️  Docker non détecté — utiliser Supabase Cloud directement"
fi

# 5. Build pour vérifier que tout compile
echo ""
echo "🏗  Build de vérification…"
npm run build

echo ""
echo "=========================================="
echo "  ✓ Sprint 1 prêt !"
echo "=========================================="
echo ""
echo "Prochaines étapes :"
echo "  1. Renseigner .env.local avec vos clés Supabase"
echo "  2. npm run dev (http://localhost:5173)"
echo "  3. Créer le projet Supabase cloud et lier : npx supabase link --project-ref <ref>"
echo "  4. Appliquer les migrations en cloud : npx supabase db push"
echo "  5. Déployer : npx vercel --prod"
echo ""
