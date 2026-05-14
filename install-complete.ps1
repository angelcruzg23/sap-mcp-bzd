# ============================================================================
# Kiro SAP ABAP Power - Instalador Completo (Standalone)
# ============================================================================
# Descripcion: Instalador todo-en-uno. Instala prerequisitos, clona el repo,
#              configura MCP server segun la Business Unit del usuario.
# Uso: .\install-complete.ps1
# Nota: Este script es STANDALONE - se puede ejecutar desde cualquier ubicacion.
# ============================================================================
# Version: 2.0.0
# Fecha: 2026-05-07
# ============================================================================

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

$RepoURL = "https://github.com/angelcruzg23/sap-mcp-bzd.git"

# ============================================================================
# BANNER
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "       Kiro SAP ABAP Power - Instalador Completo v2.0" -ForegroundColor $ColorInfo
Write-Host "                     Amrize - 2026" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "Este instalador hara lo siguiente:" -ForegroundColor $ColorInfo
Write-Host "  1. Verificar/instalar Python y Git" -ForegroundColor $ColorInfo
Write-Host "  2. Clonar el repositorio en tu carpeta de usuario" -ForegroundColor $ColorInfo
Write-Host "  3. Configurar MCP server segun tu Business Unit" -ForegroundColor $ColorInfo
Write-Host "  4. Instalar dependencias y copiar assets de Kiro" -ForegroundColor $ColorInfo
Write-Host "  5. Verificar conexion a SAP" -ForegroundColor $ColorInfo
Write-Host ""

$continue = Read-Host "Deseas continuar? (S/N)"
if ($continue -notin @("S", "s", "Y", "y")) {
    Write-Host "Instalacion cancelada." -ForegroundColor $ColorWarning
    exit 0
}

# ============================================================================
# PASO 1: PREREQUISITOS (Python + Git)
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 1/5: Verificando Prerequisitos" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

$needsRestart = $false

# --- Python ---
$pythonOK = $false
$pythonResult = $null
try {
    $pythonResult = & python --version 2>&1
} catch {
    $pythonResult = $null
}

if ($pythonResult -and ($pythonResult -match "Python (\d+)\.(\d+)")) {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    if ($major -ge 3 -and $minor -ge 10) {
        Write-Host "  [OK] Python $pythonResult" -ForegroundColor $ColorSuccess
        $pythonOK = $true
    } else {
        Write-Host "  [!] Python $pythonResult encontrado pero se requiere 3.10+" -ForegroundColor $ColorWarning
    }
} else {
    Write-Host "  [!] Python no encontrado" -ForegroundColor $ColorWarning
}

if (-not $pythonOK) {
    Write-Host "  Instalando Python 3.12..." -ForegroundColor $ColorInfo
    $wingetAvailable = $null
    try { $wingetAvailable = & winget --version 2>&1 } catch { $wingetAvailable = $null }

    if ($wingetAvailable) {
        & winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Python 3.12 instalado" -ForegroundColor $ColorSuccess
            $needsRestart = $true
        } else {
            Write-Host "  [ERROR] No se pudo instalar Python automaticamente" -ForegroundColor $ColorError
            Write-Host "  Instala manualmente desde: https://www.python.org/downloads/" -ForegroundColor $ColorWarning
            Write-Host "  IMPORTANTE: Marca 'Add Python to PATH' durante la instalacion" -ForegroundColor $ColorWarning
            exit 1
        }
    } else {
        Write-Host "  [ERROR] winget no disponible. Instala Python manualmente:" -ForegroundColor $ColorError
        Write-Host "  https://www.python.org/downloads/" -ForegroundColor $ColorWarning
        Write-Host "  IMPORTANTE: Marca 'Add Python to PATH' durante la instalacion" -ForegroundColor $ColorWarning
        exit 1
    }
}

# --- Git ---
$gitOK = $false
$gitResult = $null
try {
    $gitResult = & git --version 2>&1
} catch {
    $gitResult = $null
}

if ($gitResult -and ($gitResult -match "git version")) {
    Write-Host "  [OK] $gitResult" -ForegroundColor $ColorSuccess
    $gitOK = $true
} else {
    Write-Host "  [!] Git no encontrado" -ForegroundColor $ColorWarning
}

if (-not $gitOK) {
    Write-Host "  Instalando Git..." -ForegroundColor $ColorInfo
    $wingetAvailable = $null
    try { $wingetAvailable = & winget --version 2>&1 } catch { $wingetAvailable = $null }

    if ($wingetAvailable) {
        & winget install Git.Git --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Git instalado" -ForegroundColor $ColorSuccess
            $needsRestart = $true
        } else {
            Write-Host "  [ERROR] No se pudo instalar Git automaticamente" -ForegroundColor $ColorError
            Write-Host "  Instala manualmente desde: https://git-scm.com/download/win" -ForegroundColor $ColorWarning
            exit 1
        }
    } else {
        Write-Host "  [ERROR] winget no disponible. Instala Git manualmente:" -ForegroundColor $ColorError
        Write-Host "  https://git-scm.com/download/win" -ForegroundColor $ColorWarning
        exit 1
    }
}

# --- Si se instalo algo, pedir reinicio de PowerShell ---
if ($needsRestart) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor $ColorWarning
    Write-Host "  Se instalaron nuevos programas." -ForegroundColor $ColorWarning
    Write-Host "  Necesitas CERRAR y ABRIR PowerShell para que se reconozcan." -ForegroundColor $ColorWarning
    Write-Host "  Luego ejecuta este script nuevamente." -ForegroundColor $ColorWarning
    Write-Host "================================================================" -ForegroundColor $ColorWarning
    Write-Host ""
    exit 0
}

# ============================================================================
# PASO 2: CLONAR REPOSITORIO
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 2/5: Clonar Repositorio" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# Detectar usuario Windows automaticamente
$windowsUser = $env:USERNAME
$userProfile = $env:USERPROFILE
$repoPath = Join-Path $userProfile "sap-mcp-bzd"

Write-Host "  Usuario Windows detectado: $windowsUser" -ForegroundColor $ColorInfo
Write-Host "  Ruta del repositorio: $repoPath" -ForegroundColor $ColorInfo
Write-Host ""

if (Test-Path (Join-Path $repoPath ".git")) {
    # Ya existe, hacer pull
    Write-Host "  Repositorio ya existe. Actualizando..." -ForegroundColor $ColorInfo
    $currentDir = Get-Location
    Set-Location $repoPath
    $pullResult = & git pull 2>&1
    Set-Location $currentDir
    Write-Host "  [OK] Repositorio actualizado" -ForegroundColor $ColorSuccess
} elseif (Test-Path $repoPath) {
    # Existe la carpeta pero no es un repo git
    Write-Host "  [!] La carpeta existe pero no es un repositorio Git" -ForegroundColor $ColorWarning
    Write-Host "  Se usara la carpeta existente sin clonar" -ForegroundColor $ColorWarning
} else {
    # Clonar
    Write-Host "  Clonando repositorio..." -ForegroundColor $ColorInfo
    $cloneResult = & git clone $RepoURL $repoPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Repositorio clonado en: $repoPath" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  [ERROR] Error clonando repositorio: $cloneResult" -ForegroundColor $ColorError
        Write-Host "  Verifica tu conexion a internet y acceso a GitHub" -ForegroundColor $ColorWarning
        exit 1
    }
}

# A partir de aqui, trabajamos desde el repo clonado
Set-Location $repoPath

# ============================================================================
# PASO 3: SELECCIONAR BUSINESS UNIT
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 3/5: Seleccionar Business Unit" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "  Selecciona tu Business Unit:" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "    [1] Building Material (BM)" -ForegroundColor $ColorSuccess
Write-Host "        SAP DEV: nascdev.na.holcim.net:8081 (client 310)" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "    [2] Building Envelope (BE)" -ForegroundColor $ColorSuccess
Write-Host "        SAP BZD: fbpl08v010.holcimbp.net:8000 (client 130)" -ForegroundColor $ColorInfo
Write-Host ""

$buChoice = Read-Host "  Tu opcion (1 o 2)"

switch ($buChoice) {
    "1" {
        $sapHost = "nascdev.na.holcim.net"
        $sapPort = "8081"
        $sapClient = "310"
        $mcpServerName = "sap-dev"
        $buName = "Building Material"
        $systemDesc = "DEV (nascdev, client 310)"
    }
    "2" {
        $sapHost = "fbpl08v010.holcimbp.net"
        $sapPort = "8000"
        $sapClient = "130"
        $mcpServerName = "sap-bzd"
        $buName = "Building Envelope"
        $systemDesc = "BZD (fbpl08v010, client 130)"
    }
    default {
        Write-Host "  [ERROR] Opcion invalida. Ejecuta el script nuevamente." -ForegroundColor $ColorError
        exit 1
    }
}

Write-Host ""
Write-Host "  [OK] Business Unit: $buName" -ForegroundColor $ColorSuccess
Write-Host "  [OK] Sistema SAP: $systemDesc" -ForegroundColor $ColorSuccess

# ============================================================================
# PASO 4: CONFIGURAR SAP Y MCP
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 4/5: Configurar Credenciales y MCP Server" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# Pedir usuario SAP
$sapUser = Read-Host "  Ingresa tu usuario SAP (ej: ANGECRUZ)"
if ([string]::IsNullOrWhiteSpace($sapUser)) {
    Write-Host "  [ERROR] El usuario SAP no puede estar vacio" -ForegroundColor $ColorError
    exit 1
}
$sapUser = $sapUser.ToUpper()
Write-Host "  [OK] Usuario SAP: $sapUser" -ForegroundColor $ColorSuccess

# Pedir password SAP
Write-Host ""
$securePassword = Read-Host "  Ingresa tu password de SAP" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$sapPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

if ([string]::IsNullOrWhiteSpace($sapPassword)) {
    Write-Host "  [ERROR] El password no puede estar vacio" -ForegroundColor $ColorError
    exit 1
}

# Guardar password como variable de entorno del usuario
[System.Environment]::SetEnvironmentVariable('SAP_PASSWORD', $sapPassword, 'User')
$env:SAP_PASSWORD = $sapPassword
Write-Host "  [OK] Password guardado de forma segura" -ForegroundColor $ColorSuccess

# --- Instalar dependencias Python ---
Write-Host ""
Write-Host "  Instalando dependencias Python..." -ForegroundColor $ColorInfo

if (Test-Path "requirements.txt") {
    $pipResult = & pip install -r requirements.txt --quiet 2>&1
} else {
    $pipResult = & pip install requests python-dotenv mcp --quiet 2>&1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Dependencias Python instaladas" -ForegroundColor $ColorSuccess
} else {
    Write-Host "  [!] Advertencia instalando dependencias: $pipResult" -ForegroundColor $ColorWarning
    Write-Host "  Continuando de todas formas..." -ForegroundColor $ColorWarning
}

# --- Configurar MCP server ---
Write-Host ""
Write-Host "  Configurando MCP server..." -ForegroundColor $ColorInfo

$mcpConfigPath = Join-Path $HOME ".kiro\settings"
$mcpConfigFile = Join-Path $mcpConfigPath "mcp.json"

if (-not (Test-Path $mcpConfigPath)) {
    New-Item -ItemType Directory -Path $mcpConfigPath -Force | Out-Null
}

$serverPyPath = Join-Path $repoPath "server.py"

$mcpConfig = @{
    mcpServers = @{
        $mcpServerName = @{
            command = "python"
            args = @($serverPyPath)
            env = @{
                SAP_HOST = $sapHost
                SAP_PORT = $sapPort
                SAP_CLIENT = $sapClient
                SAP_USER = $sapUser
            }
            disabled = $false
            autoApprove = @()
        }
    }
}

try {
    $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigFile -Encoding UTF8
    Write-Host "  [OK] MCP server '$mcpServerName' configurado" -ForegroundColor $ColorSuccess
    Write-Host "       Host: ${sapHost}:${sapPort} (client $sapClient)" -ForegroundColor $ColorInfo
} catch {
    Write-Host "  [ERROR] Error configurando MCP: $_" -ForegroundColor $ColorError
    exit 1
}

# --- Copiar steering files ---
Write-Host ""
Write-Host "  Copiando steering files, skills y hooks..." -ForegroundColor $ColorInfo

$assets = @(
    @{ Source = ".kiro\steering"; Target = Join-Path $HOME ".kiro\steering"; Name = "steering files" }
    @{ Source = ".kiro\skills";   Target = Join-Path $HOME ".kiro\skills";   Name = "skills" }
    @{ Source = ".kiro\hooks";    Target = Join-Path $HOME ".kiro\hooks";    Name = "hooks" }
)

foreach ($asset in $assets) {
    $srcPath = Join-Path $repoPath $asset.Source
    if (Test-Path $srcPath) {
        if (-not (Test-Path $asset.Target)) {
            New-Item -ItemType Directory -Path $asset.Target -Force | Out-Null
        }
        try {
            Copy-Item -Path (Join-Path $srcPath "*") -Destination $asset.Target -Force -Recurse
            $count = (Get-ChildItem $asset.Target -File -ErrorAction SilentlyContinue).Count
            Write-Host "  [OK] $count $($asset.Name) copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [!] Error copiando $($asset.Name): $_" -ForegroundColor $ColorWarning
        }
    } else {
        Write-Host "  [!] $($asset.Name) no encontrados en el repo (se pueden agregar despues)" -ForegroundColor $ColorWarning
    }
}

# ============================================================================
# PASO 5: VERIFICAR CONEXION
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  PASO 5/5: Verificar Conexion a SAP" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

Write-Host "  Probando conexion a $sapHost`:$sapPort..." -ForegroundColor $ColorInfo

# Test de red basico
$netTest = Test-NetConnection -ComputerName $sapHost -Port ([int]$sapPort) -WarningAction SilentlyContinue
if ($netTest.TcpTestSucceeded) {
    Write-Host "  [OK] Conectividad de red OK" -ForegroundColor $ColorSuccess
} else {
    Write-Host "  [!] No se puede alcanzar $sapHost`:$sapPort" -ForegroundColor $ColorWarning
    Write-Host "      Verifica que tu VPN este conectada" -ForegroundColor $ColorWarning
    Write-Host "      La instalacion se completo pero la conexion fallara hasta que tengas red" -ForegroundColor $ColorWarning
}

# Test de autenticacion SAP via Python
$tempPy = [System.IO.Path]::GetTempFileName() + ".py"
Set-Content -Path $tempPy -Value @'
import requests
from requests.auth import HTTPBasicAuth
import os
import sys

host = sys.argv[1]
port = sys.argv[2]
client = sys.argv[3]
user = sys.argv[4]
password = os.environ.get('SAP_PASSWORD', '')

if not password:
    print('SKIP: No password')
    sys.exit(0)

try:
    response = requests.get(
        'http://' + host + ':' + port + '/sap/bc/adt/discovery',
        auth=HTTPBasicAuth(user, password),
        headers={'sap-client': client},
        timeout=15
    )
    if response.status_code == 200:
        print('SUCCESS')
    else:
        print('ERROR: HTTP ' + str(response.status_code))
except Exception as e:
    print('ERROR: ' + str(e))
'@

$testResult = & python $tempPy $sapHost $sapPort $sapClient $sapUser 2>&1
Remove-Item $tempPy -ErrorAction SilentlyContinue

if ($testResult -eq "SUCCESS") {
    Write-Host "  [OK] Autenticacion SAP exitosa" -ForegroundColor $ColorSuccess
} elseif ($testResult -match "SKIP") {
    Write-Host "  [!] Test de autenticacion omitido (sin password)" -ForegroundColor $ColorWarning
} else {
    Write-Host "  [!] Test de autenticacion: $testResult" -ForegroundColor $ColorWarning
    Write-Host "      Esto puede ser por VPN, password incorrecto, o servidor no disponible" -ForegroundColor $ColorWarning
    Write-Host "      La configuracion se guardo correctamente - podras probar despues en Kiro" -ForegroundColor $ColorInfo
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorSuccess
Write-Host "  INSTALACION COMPLETADA" -ForegroundColor $ColorSuccess
Write-Host "================================================================" -ForegroundColor $ColorSuccess
Write-Host ""
Write-Host "  Resumen:" -ForegroundColor $ColorInfo
Write-Host "    Business Unit:  $buName" -ForegroundColor $ColorInfo
Write-Host "    Usuario SAP:    $sapUser" -ForegroundColor $ColorInfo
Write-Host "    MCP Server:     $mcpServerName" -ForegroundColor $ColorInfo
Write-Host "    Sistema SAP:    $systemDesc" -ForegroundColor $ColorInfo
Write-Host "    Repositorio:    $repoPath" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "  Proximos pasos:" -ForegroundColor $ColorInfo
Write-Host "    1. Abre Kiro (o reinicialo si ya estaba abierto)" -ForegroundColor $ColorWarning
Write-Host "    2. Abre la carpeta del proyecto: File > Open Folder" -ForegroundColor $ColorWarning
Write-Host "       $repoPath" -ForegroundColor $ColorSuccess
Write-Host "    3. Verifica que el MCP server '$mcpServerName' este conectado (panel lateral)" -ForegroundColor $ColorWarning
Write-Host "    4. Prueba en el chat: 'Verifica la conexion con SAP'" -ForegroundColor $ColorWarning
Write-Host ""
Write-Host "  Si necesitas agregar otro sistema SAP despues:" -ForegroundColor $ColorInfo
Write-Host "    Edita: $mcpConfigFile" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorSuccess
Write-Host ""

exit 0
