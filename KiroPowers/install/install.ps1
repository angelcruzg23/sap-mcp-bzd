# ============================================================
# Kiro Power: SAP ABAP Amrize BP — Instalador
# ============================================================
# Uso: .\KiroPowers\install\install.ps1 -SAPUser "TU_USUARIO"
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SAPUser,

    [Parameter(Mandatory=$false)]
    [string]$SAPUserBZN = "AHERNA11",

    [Parameter(Mandatory=$false)]
    [string]$MCPServerPath = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Kiro Power: SAP ABAP Amrize BP" -ForegroundColor Cyan
Write-Host "  Instalador v1.0.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Verificar Python ──────────────────────────────────────
Write-Host "[1/6] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✅ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Python no encontrado. Instala Python 3.10+ antes de continuar." -ForegroundColor Red
    Write-Host "     Opciones: winget install Python.Python.3.12" -ForegroundColor Gray
    Write-Host "               o Microsoft Store → Python 3.12" -ForegroundColor Gray
    exit 1
}

# ── 2. Verificar/instalar dependencias Python ────────────────
Write-Host "[2/6] Verificando dependencias Python..." -ForegroundColor Yellow
$mcpInstalled = pip show mcp 2>&1
$requestsInstalled = pip show requests 2>&1

if ($mcpInstalled -match "Name: mcp") {
    Write-Host "  ✅ mcp instalado" -ForegroundColor Green
} else {
    Write-Host "  📦 Instalando mcp..." -ForegroundColor Yellow
    pip install "mcp>=1.0.0" --quiet
    Write-Host "  ✅ mcp instalado" -ForegroundColor Green
}

if ($requestsInstalled -match "Name: requests") {
    Write-Host "  ✅ requests instalado" -ForegroundColor Green
} else {
    Write-Host "  📦 Instalando requests..." -ForegroundColor Yellow
    pip install "requests>=2.31.0" --quiet
    Write-Host "  ✅ requests instalado" -ForegroundColor Green
}

# ── 3. Determinar ruta del MCP server ────────────────────────
Write-Host "[3/6] Configurando ruta del MCP server..." -ForegroundColor Yellow

if ($MCPServerPath -eq "") {
    # Buscar server.py en el directorio padre del instalador
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $powerDir  = Split-Path -Parent $scriptDir
    $repoRoot  = Split-Path -Parent $powerDir
    $serverPath = Join-Path $repoRoot "server.py"

    if (-not (Test-Path $serverPath)) {
        Write-Host "  ⚠️  No se encontró server.py en $repoRoot" -ForegroundColor Yellow
        $serverPath = Read-Host "  Ingresa la ruta completa a server.py"
    }
} else {
    $serverPath = $MCPServerPath
}

Write-Host "  ✅ MCP server: $serverPath" -ForegroundColor Green

# ── 4. Solicitar passwords ───────────────────────────────────
Write-Host "[4/6] Configurando credenciales SAP..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Sistema BZD (Desarrollo) — Usuario: $SAPUser" -ForegroundColor White
$passwordBZD = Read-Host "  Password BZD" -AsSecureString
$passwordBZDPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordBZD))

Write-Host ""
Write-Host "  Sistema BZN (Sandbox) — Usuario: $SAPUserBZN" -ForegroundColor White
$passwordBZN = Read-Host "  Password BZN (Enter para omitir)" -AsSecureString
$passwordBZNPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordBZN))

# ── 5. Generar mcp.json con credenciales reales ──────────────
Write-Host ""
Write-Host "[5/6] Generando configuración MCP..." -ForegroundColor Yellow

$kiroSettingsDir = Join-Path $env:USERPROFILE ".kiro\settings"
if (-not (Test-Path $kiroSettingsDir)) {
    New-Item -ItemType Directory -Path $kiroSettingsDir -Force | Out-Null
}

$mcpJsonPath = Join-Path $kiroSettingsDir "mcp.json"

$mcpConfig = @{
    mcpServers = @{
        "sap-bzd" = @{
            command = "python"
            args = @($serverPath)
            env = @{
                SAP_HOST      = "fbpl08v010.holcimbp.net:8000"
                SAP_CLIENT    = "130"
                SAP_USER      = $SAPUser.ToUpper()
                SAP_PASSWORD  = $passwordBZDPlain
                SAP_SECURE    = "false"
                SAP_SYSTEM_ID = "BZD"
            }
            timeout = 60000
            autoApprove = @(
                "sap_ping", "sap_get_program_source", "sap_get_include_source",
                "sap_get_class_source", "sap_get_function_module_source",
                "sap_search_objects", "sap_get_table_definition",
                "sap_check_adt_capabilities", "sap_test_endpoint",
                "sap_syntax_check", "sap_list_transports",
                "sap_get_transport_details", "sap_get_transport_xml_raw",
                "sap_run_abap_unit"
            )
        }
    }
}

if ($passwordBZNPlain -ne "") {
    $mcpConfig.mcpServers["sap-bzn"] = @{
        command = "python"
        args = @($serverPath)
        env = @{
            SAP_HOST      = "lfh02a09ld075.holcimbp.net:8040"
            SAP_CLIENT    = "100"
            SAP_USER      = $SAPUserBZN.ToUpper()
            SAP_PASSWORD  = $passwordBZNPlain
            SAP_SECURE    = "false"
            SAP_SYSTEM_ID = "BZN"
        }
        timeout = 60000
        autoApprove = @(
            "sap_ping", "sap_get_program_source", "sap_get_include_source",
            "sap_get_class_source", "sap_get_function_module_source",
            "sap_search_objects", "sap_get_table_definition",
            "sap_syntax_check", "sap_run_abap_unit"
        )
    }
}

$mcpConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $mcpJsonPath -Encoding UTF8
Write-Host "  ✅ mcp.json generado en: $mcpJsonPath" -ForegroundColor Green

# ── 6. Copiar steering files, skills y hooks ─────────────────
Write-Host "[6/6] Instalando steering files, skills y hooks..." -ForegroundColor Yellow

$powerDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$kiroDir  = Join-Path $env:USERPROFILE ".kiro"

# Steering files
$steeringDest = Join-Path $kiroDir "steering"
if (-not (Test-Path $steeringDest)) { New-Item -ItemType Directory -Path $steeringDest -Force | Out-Null }
$steeringSrc = Join-Path $powerDir "steering"
if (Test-Path $steeringSrc) {
    Copy-Item "$steeringSrc\*" -Destination $steeringDest -Force
    Write-Host "  ✅ Steering files copiados" -ForegroundColor Green
}

# Skills
$skillsDest = Join-Path $kiroDir "skills"
if (-not (Test-Path $skillsDest)) { New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null }
$skillsSrc = Join-Path $powerDir "skills"
if (Test-Path $skillsSrc) {
    Copy-Item "$skillsSrc\*" -Destination $skillsDest -Force
    Write-Host "  ✅ Skills copiados" -ForegroundColor Green
}

# Hooks (copiar al workspace .kiro/hooks)
$workspaceHooksDest = Join-Path (Get-Location) ".kiro\hooks"
if (-not (Test-Path $workspaceHooksDest)) { New-Item -ItemType Directory -Path $workspaceHooksDest -Force | Out-Null }
$hooksSrc = Join-Path $powerDir "hooks"
if (Test-Path $hooksSrc) {
    # Convertir .json a .kiro.hook
    Get-ChildItem "$hooksSrc\*.json" | ForEach-Object {
        $destName = $_.BaseName + ".kiro.hook"
        Copy-Item $_.FullName -Destination (Join-Path $workspaceHooksDest $destName) -Force
    }
    Write-Host "  ✅ Hooks copiados" -ForegroundColor Green
}

# ── Resumen ──────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ✅ Instalación completada" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Próximos pasos:" -ForegroundColor White
Write-Host "  1. Reinicia Kiro (File → Exit y vuelve a abrir)" -ForegroundColor Gray
Write-Host "  2. Verifica los MCP servers en el panel lateral" -ForegroundColor Gray
Write-Host "  3. En el chat escribe: Verifica la conexion con SAP BZD" -ForegroundColor Gray
Write-Host ""
