# ============================================================================
# Kiro SAP ABAP Power - Setup Simple (sin emojis)
# ============================================================================
# Descripcion: Version simplificada del asistente de configuracion
# Uso: .\setup-simple.ps1
# ============================================================================

param(
    [string]$SystemKey = "BZD",
    [string]$Username = "",
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Kiro SAP ABAP Power - Setup Simple" -ForegroundColor Cyan
Write-Host "  Amrize BP - 2026" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar Python
Write-Host "[1/6] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  OK: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Python no encontrado" -ForegroundColor Red
    Write-Host "  Instala Python 3.8+ desde python.org" -ForegroundColor Red
    exit 1
}

# Solicitar datos si no se proporcionaron
if ([string]::IsNullOrEmpty($Username)) {
    Write-Host ""
    $Username = Read-Host "Usuario SAP para $SystemKey"
}

if ([string]::IsNullOrEmpty($Password)) {
    Write-Host "Password SAP para $SystemKey (se guardara de forma segura)"
    $securePassword = Read-Host "Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# Cargar configuracion de sistemas
Write-Host ""
Write-Host "[2/6] Cargando configuracion de sistemas..." -ForegroundColor Yellow

if (-not (Test-Path "config-systems.json")) {
    Write-Host "  ERROR: config-systems.json no encontrado" -ForegroundColor Red
    exit 1
}

$systemsConfig = Get-Content "config-systems.json" | ConvertFrom-Json
$system = $systemsConfig.systems.$SystemKey

if ($null -eq $system) {
    Write-Host "  ERROR: Sistema $SystemKey no encontrado en config-systems.json" -ForegroundColor Red
    exit 1
}

Write-Host "  OK: Sistema $SystemKey - $($system.name)" -ForegroundColor Green
Write-Host "      Host: $($system.host):$($system.port)" -ForegroundColor Cyan
Write-Host "      Cliente: $($system.client)" -ForegroundColor Cyan

# Configurar variable de entorno
Write-Host ""
Write-Host "[3/6] Configurando variables de entorno..." -ForegroundColor Yellow

$envVarName = "SAP_PASSWORD_$SystemKey"

try {
    # Configurar a nivel de usuario (permanente)
    [System.Environment]::SetEnvironmentVariable($envVarName, $Password, 'User')
    
    # Tambien configurar para la sesion actual
    Set-Item -Path "env:$envVarName" -Value $Password
    
    Write-Host "  OK: $envVarName configurado" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: No se pudo configurar $envVarName" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# Generar configuracion MCP
Write-Host ""
Write-Host "[4/6] Generando configuracion MCP..." -ForegroundColor Yellow

$projectPath = (Get-Location).Path
$mcpConfigPath = "$HOME\.kiro\settings"
$mcpConfigFile = "$mcpConfigPath\mcp.json"

if (-not (Test-Path $mcpConfigPath)) {
    New-Item -ItemType Directory -Path $mcpConfigPath -Force | Out-Null
}

$serverKey = "sap-$($SystemKey.ToLower())"

$mcpConfig = @{
    mcpServers = @{
        $serverKey = @{
            command = "python"
            args = @("$projectPath\server.py")
            env = @{
                SAP_HOST = "$($system.host):$($system.port)"
                SAP_CLIENT = $system.client
                SAP_USER = $Username
                SAP_SECURE = "false"
                SAP_SYSTEM_ID = $SystemKey
            }
            disabled = $false
            autoApprove = @()
            timeout = 60000
        }
    }
}

try {
    $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigFile -Encoding UTF8
    Write-Host "  OK: Configuracion guardada en $mcpConfigFile" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: No se pudo guardar configuracion MCP" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# Instalar dependencias Python
Write-Host ""
Write-Host "[5/6] Instalando dependencias Python..." -ForegroundColor Yellow

if (Test-Path "requirements.txt") {
    try {
        pip install -r requirements.txt --quiet
        Write-Host "  OK: Dependencias instaladas" -ForegroundColor Green
    } catch {
        Write-Host "  ADVERTENCIA: Error instalando dependencias" -ForegroundColor Yellow
        Write-Host "  $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ADVERTENCIA: requirements.txt no encontrado" -ForegroundColor Yellow
}

# Verificar conexion
Write-Host ""
Write-Host "[6/6] Verificando conexion a SAP..." -ForegroundColor Yellow

$testScript = @"
import requests
from requests.auth import HTTPBasicAuth
import sys

host = '$($system.host)'
port = '$($system.port)'
client = '$($system.client)'
user = '$Username'
password = '$Password'

try:
    response = requests.get(
        f'http://{host}:{port}/sap/bc/adt/discovery',
        auth=HTTPBasicAuth(user, password),
        headers={'sap-client': client},
        timeout=10
    )
    if response.status_code == 200:
        print('SUCCESS')
        sys.exit(0)
    else:
        print(f'ERROR:{response.status_code}')
        sys.exit(1)
except Exception as e:
    print(f'ERROR:{str(e)}')
    sys.exit(1)
"@

try {
    $result = $testScript | python
    
    if ($result -eq "SUCCESS") {
        Write-Host "  OK: Conexion exitosa a $SystemKey" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: $result" -ForegroundColor Red
        Write-Host "  Verifica usuario y password" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR: No se pudo verificar conexion" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
}

# Resumen
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Setup completado" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Sistema configurado:" -ForegroundColor Cyan
Write-Host "  - Sistema: $SystemKey - $($system.name)" -ForegroundColor White
Write-Host "  - Usuario: $Username" -ForegroundColor White
Write-Host "  - MCP Server: $serverKey" -ForegroundColor White
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Reinicia Kiro para aplicar los cambios" -ForegroundColor White
Write-Host "  2. Verifica que el MCP server este conectado (panel lateral)" -ForegroundColor White
Write-Host "  3. Prueba con: 'Verifica la conexion con SAP $SystemKey'" -ForegroundColor White
Write-Host ""
Write-Host "Para configurar mas sistemas, ejecuta:" -ForegroundColor Yellow
Write-Host "  .\setup-simple.ps1 -SystemKey BZN -Username TU_USUARIO" -ForegroundColor White
Write-Host ""

exit 0
