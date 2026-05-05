# ============================================================================
# Kiro SAP ABAP Power - Instalador Completo (Todo-en-Uno)
# ============================================================================
# Descripcion: Instala prerequisitos Y configura Kiro en un solo paso
# Uso: .\install-complete.ps1 -SAPUser "TU_USUARIO_SAP"
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SAPUser,
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultSystem = "BZD"
)

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  Kiro SAP ABAP Power - Instalador Completo" -ForegroundColor $ColorInfo
Write-Host "  Amrize BP - 2026" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "Este instalador hara lo siguiente:" -ForegroundColor $ColorInfo
Write-Host "  1. Verificar e instalar Python 3.12 (si es necesario)" -ForegroundColor $ColorInfo
Write-Host "  2. Verificar e instalar Git (si es necesario)" -ForegroundColor $ColorInfo
Write-Host "  3. Instalar dependencias Python" -ForegroundColor $ColorInfo
Write-Host "  4. Configurar MCP servers para SAP" -ForegroundColor $ColorInfo
Write-Host "  5. Copiar steering files, skills, hooks y templates" -ForegroundColor $ColorInfo
Write-Host "  6. Verificar conexion a SAP" -ForegroundColor $ColorInfo
Write-Host ""

$continue = Read-Host "Deseas continuar? (S/N)"
if ($continue -ne "S" -and $continue -ne "s") {
    Write-Host "Instalacion cancelada por el usuario" -ForegroundColor $ColorWarning
    exit 0
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 1/2: Instalando Prerequisitos" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# Ejecutar instalador de prerequisitos
if (Test-Path ".\install-prerequisites.ps1") {
    & ".\install-prerequisites.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host "  ERROR: Fallo la instalacion de prerequisitos" -ForegroundColor $ColorError
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host ""
        Write-Host "Acciones requeridas:" -ForegroundColor $ColorWarning
        Write-Host "  1. Revisa los errores arriba" -ForegroundColor $ColorWarning
        Write-Host "  2. Instala los prerequisitos manualmente" -ForegroundColor $ColorWarning
        Write-Host "  3. Cierra y abre PowerShell nuevamente" -ForegroundColor $ColorWarning
        Write-Host "  4. Ejecuta este script nuevamente" -ForegroundColor $ColorWarning
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "[ERROR] No se encontro install-prerequisites.ps1" -ForegroundColor $ColorError
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 2/2: Configurando Kiro SAP ABAP Power" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# Preguntar si necesita reiniciar PowerShell
Write-Host "Si acabas de instalar Python, necesitas cerrar y abrir PowerShell" -ForegroundColor $ColorWarning
Write-Host "antes de continuar con la instalacion." -ForegroundColor $ColorWarning
Write-Host ""
$continueInstall = Read-Host "Ya reiniciaste PowerShell o Python ya estaba instalado? (S/N)"

if ($continueInstall -ne "S" -and $continueInstall -ne "s") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor $ColorInfo
    Write-Host "  Instalacion pausada" -ForegroundColor $ColorInfo
    Write-Host "================================================================" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Cierra PowerShell completamente" -ForegroundColor $ColorWarning
    Write-Host "  2. Abre PowerShell nuevamente" -ForegroundColor $ColorWarning
    Write-Host "  3. Navega a la carpeta del proyecto:" -ForegroundColor $ColorInfo
    Write-Host "     cd $((Get-Location).Path)" -ForegroundColor $ColorSuccess
    Write-Host "  4. Ejecuta el instalador:" -ForegroundColor $ColorInfo
    Write-Host "     .\install.ps1 -SAPUser '$SAPUser'" -ForegroundColor $ColorSuccess
    Write-Host ""
    exit 0
}

Write-Host ""

# Ejecutar instalador principal
if (Test-Path ".\install.ps1") {
    & ".\install.ps1" -SAPUser $SAPUser -DefaultSystem $DefaultSystem
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor $ColorSuccess
        Write-Host "  INSTALACION COMPLETA EXITOSA" -ForegroundColor $ColorSuccess
        Write-Host "================================================================" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "Proximos pasos:" -ForegroundColor $ColorInfo
        Write-Host "  1. Reinicia Kiro (cierra y abre completamente)" -ForegroundColor $ColorWarning
        Write-Host "  2. Verifica que los MCP servers esten conectados" -ForegroundColor $ColorWarning
        Write-Host "  3. Prueba con: 'Verifica la conexion con SAP BZD'" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "Documentacion:" -ForegroundColor $ColorInfo
        Write-Host "  - QUICK_START.md - Guia rapida" -ForegroundColor $ColorInfo
        Write-Host "  - ONBOARDING_NUEVO_DESARROLLADOR.md - Guia completa" -ForegroundColor $ColorInfo
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host "  ERROR: Fallo la configuracion de Kiro" -ForegroundColor $ColorError
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host ""
        Write-Host "Revisa los errores arriba y contacta al equipo SAP si necesitas ayuda" -ForegroundColor $ColorWarning
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "[ERROR] No se encontro install.ps1" -ForegroundColor $ColorError
    exit 1
}

exit 0
