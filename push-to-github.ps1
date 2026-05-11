# =========================================================
# DJAWAL V2 — Push initial vers GitHub
# Repo cible : https://github.com/kherbouchehamid23-cpu/DJAWAL-V2
#
# Usage :
#   Clic droit sur ce fichier → "Exécuter avec PowerShell"
#   OU dans un terminal PowerShell :
#     cd C:\Users\Pc\Documents\Claude\Projects\DJAWAL\djawal-v2
#     .\push-to-github.ps1
#
# Si la première push demande une authentification, ton navigateur
# s'ouvrira sur GitHub pour autoriser Git — accepter et c'est fait.
# =========================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " DJAWAL V2 — Push initial vers GitHub" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier qu'on est dans le bon dossier
$expectedDir = "djawal-v2"
if ((Split-Path -Leaf (Get-Location)) -ne $expectedDir) {
    Write-Host "Changement de répertoire vers djawal-v2..." -ForegroundColor Yellow
    Set-Location $PSScriptRoot
}

# Vérifier Git
try {
    $gitVersion = git --version
    Write-Host "Git détecté : $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git n'est pas installé. Télécharger : https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

# 1. Initialiser le dépôt git si pas déjà fait
if (-not (Test-Path ".git")) {
    Write-Host ""
    Write-Host "[1/5] Initialisation du dépôt git..." -ForegroundColor Cyan
    git init
    git branch -M main
} else {
    Write-Host "[1/5] Dépôt git déjà initialisé." -ForegroundColor Green
}

# 2. Configurer le remote
$remoteUrl = "https://github.com/kherbouchehamid23-cpu/DJAWAL-V2.git"
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote -eq $remoteUrl) {
    Write-Host "[2/5] Remote 'origin' déjà configuré." -ForegroundColor Green
} elseif ($existingRemote) {
    Write-Host "[2/5] Mise à jour du remote 'origin'..." -ForegroundColor Cyan
    git remote set-url origin $remoteUrl
} else {
    Write-Host "[2/5] Ajout du remote 'origin'..." -ForegroundColor Cyan
    git remote add origin $remoteUrl
}

# 3. Pull pour récupérer le README initial créé par GitHub
Write-Host ""
Write-Host "[3/5] Synchronisation avec le dépôt distant (récupération du README initial)..." -ForegroundColor Cyan
try {
    git fetch origin main
    # Rebase pour éviter un merge commit inutile
    git reset --soft origin/main 2>$null
    Write-Host "  Le README initial GitHub sera remplacé par notre README détaillé." -ForegroundColor Yellow
} catch {
    Write-Host "  (Premier push — pas de remote à synchroniser, on continue.)" -ForegroundColor Yellow
}

# 4. Ajouter tous les fichiers + commit
Write-Host ""
Write-Host "[4/5] Préparation du commit initial..." -ForegroundColor Cyan
git add .
$pendingFiles = (git diff --cached --name-only | Measure-Object -Line).Lines
Write-Host "  $pendingFiles fichiers prêts à committer."

# Configuration git locale si nécessaire (n'écrase pas la config globale)
$userName = git config user.name
if (-not $userName) {
    git config user.name "kherbouche hamid"
    git config user.email "kherbouche.hamid23@gmail.com"
    Write-Host "  Configuration locale appliquée (nom + email)." -ForegroundColor Yellow
}

git commit -m "feat: Sprint 1 — fondations Djawal V2

- Scaffold Vue 3 + Vuetify + Vite + PWA
- Design system avec 3 themes culturels (Saharien, Mauresque, Aures)
- Migration SQL : 12 tables, pgvector, PostGIS, RLS complete
- Auth/Theme stores Pinia, Supabase client
- Header, Footer, HomePage avec switcher de theme
- Config CI GitHub Actions + Vercel + Lighthouse
- Documentation CLAUDE.md pour les prochains sprints"

# 5. Push
Write-Host ""
Write-Host "[5/5] Push vers GitHub..." -ForegroundColor Cyan
Write-Host "  Si une fenetre de connexion s'ouvre, autorise Git dans ton navigateur." -ForegroundColor Yellow
git push -u origin main --force-with-lease

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host " Sprint 1 pousse avec succes !" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Repo : https://github.com/kherbouchehamid23-cpu/DJAWAL-V2" -ForegroundColor Cyan
Write-Host "CI : https://github.com/kherbouchehamid23-cpu/DJAWAL-V2/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines etapes :" -ForegroundColor White
Write-Host "  1. Creer un projet Supabase : https://app.supabase.com" -ForegroundColor Gray
Write-Host "  2. Creer un projet Vercel et le lier au repo : https://vercel.com" -ForegroundColor Gray
Write-Host "  3. Renseigner les variables d'env dans Vercel dashboard" -ForegroundColor Gray
Write-Host "  4. Lancer le Sprint 2 (Auth & roles) avec Claude Code" -ForegroundColor Gray
Write-Host ""
