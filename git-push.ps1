# git-push.ps1 — Actualiza GitHub con todos los cambios del workspace
# Uso: ejecutar desde el hook "Actualizar GitHub" en Kiro
# o manualmente: powershell -File git-push.ps1 "mensaje opcional"

$ErrorActionPreference = "Stop"

$MSG = if ($args[0]) { $args[0] } else { "Actualizacion automatica desde Kiro - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

Write-Host "=== Actualizando GitHub ==="
$branch = git branch --show-current
Write-Host "Rama: $branch"
Write-Host "Remote: $(git remote get-url origin)"
Write-Host ""

# Mostrar qué archivos se van a commitear
Write-Host "--- Cambios detectados ---"
git status --short
Write-Host ""

# Agregar todos los cambios (respeta .gitignore)
git add .

# Verificar si hay algo para commitear
$diff = git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "No hay cambios nuevos para commitear."
    exit 0
}

# Commit
git commit -m $MSG

# Push a la rama actual
git push origin $branch

Write-Host ""
Write-Host "=== Listo! Cambios subidos a origin/$branch ==="
