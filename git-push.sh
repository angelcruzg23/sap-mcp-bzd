#!/bin/bash
# git-push.sh — Actualiza GitHub con todos los cambios del workspace
# Uso: ejecutar desde el hook "Actualizar GitHub" en Kiro
# o manualmente: bash git-push.sh "mensaje opcional"

set -e  # Detener si cualquier comando falla

MSG="${1:-Actualizacion automatica desde Kiro - $(date '+%Y-%m-%d %H:%M')}"

echo "=== Actualizando GitHub ==="
echo "Rama: $(git branch --show-current)"
echo "Remote: $(git remote get-url origin)"
echo ""

# Mostrar qué archivos se van a commitear
echo "--- Cambios detectados ---"
git status --short
echo ""

# Agregar todos los cambios (respeta .gitignore)
git add .

# Verificar si hay algo para commitear
if git diff --cached --quiet; then
  echo "No hay cambios nuevos para commitear."
  exit 0
fi

# Commit
git commit -m "$MSG"

# Push a la rama actual
BRANCH=$(git branch --show-current)
git push origin "$BRANCH"

echo ""
echo "=== Listo! Cambios subidos a origin/$BRANCH ==="
