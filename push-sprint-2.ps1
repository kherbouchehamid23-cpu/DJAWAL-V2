# =========================================================
# DJAWAL V2 — Sprint 2 : push automatique
# =========================================================
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " DJAWAL V2 — Push Sprint 2 (Auth & KYC)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

# Vérifier que le repo git est initialisé
if (-not (Test-Path ".git")) {
    Write-Host "Initialisation Git..." -ForegroundColor Yellow
    git init
    git branch -M main
    git remote add origin https://github.com/kherbouchehamid23-cpu/DJAWAL-V2.git
}

# Configurer l'identité si absente
if (-not (git config user.name)) {
    git config user.name "kherbouche hamid"
    git config user.email "kherbouche.hamid23@gmail.com"
}

# Récupérer l'état distant
Write-Host "[1/3] Récupération de l'état distant..." -ForegroundColor Cyan
try {
    git fetch origin main 2>&1 | Out-Null
    git reset --soft origin/main 2>&1 | Out-Null
} catch {
    Write-Host "  (Aucun remote trouvé, on continue.)" -ForegroundColor Yellow
}

# Ajouter et commiter
Write-Host "[2/3] Préparation du commit..." -ForegroundColor Cyan
git add .

$pending = (git diff --cached --name-only | Measure-Object -Line).Lines
Write-Host "  $pending fichiers modifiés/ajoutés."

git commit -m "feat: Sprint 2 - Auth, roles, KYC

- Migration SQL 0002 : buckets storage + table kyc_documents + policies
- Store auth Pinia : signin email, signup, OAuth Google, magic link, reset
- Router guards (requiresAuth + requiresRole) avec redirections par role
- Pages auth : Login, Signup, Callback, ConfirmEmail, ResetPassword
- Composant AuthCard split-view avec design culturel
- MyAccountPage : profil voyageur + acces rapide guide/admin
- KycPage : upload 4 documents + validation Supabase Storage
- GuideDashboardPage placeholder avec banniere KYC
- AdminDashboardPage avec stats + modules
- KycValidationPage : revue documents + approve/reject/promote senior
- main.ts : initialize auth au demarrage"

# Push
Write-Host "[3/3] Push vers GitHub..." -ForegroundColor Cyan
git push -u origin main

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host " Sprint 2 pousse !" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Vercel va re-deployer automatiquement (~1 minute)" -ForegroundColor Cyan
Write-Host "Voir : https://vercel.com/kherbouchehamid23-cpus-projects/djawal-v2/deployments" -ForegroundColor Cyan
Write-Host ""
