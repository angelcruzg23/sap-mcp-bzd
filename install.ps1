# ============================================================================
# Kiro SAP ABAP Power - Instalador Automatico
# ============================================================================
# Descripcion: Configura automaticamente el ambiente de Kiro para SAP ABAP
# Autor: Equipo SAP ABAP - Amrize BP
# Version: 1.0.0
# Fecha: 2026-05-04
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SAPUser,

    [Parameter(Mandatory=$false)]
    [string]$DefaultSystem = "BZD",

    [Parameter(Mandatory=$false)]
    [switch]$SkipPasswordPrompt
)

# Colores para output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Banner
Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "       Kiro SAP ABAP Power - Instalador v1.0.0" -ForegroundColor $ColorInfo
Write-Host "                  Amrize BP - 2026" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# ============================================================================
# Funcion: Verificar prerequisitos
# ============================================================================
function Test-Prerequisites {
    Write-Host "Verificando prerequisitos..." -ForegroundColor $ColorInfo
    Write-Host ""

    $hasErrors = $false

    # Verificar Python
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
            Write-Host "  [OK] Python $pythonResult instalado" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  [ERROR] Python 3.10+ requerido. Version actual: $pythonResult" -ForegroundColor $ColorError
            Write-Host "          El paquete 'mcp' requiere Python 3.10 como minimo" -ForegroundColor $ColorError
            $hasErrors = $true
        }
    } else {
        Write-Host "  [ERROR] Python no encontrado" -ForegroundColor $ColorError
        $hasErrors = $true
    }

    # Verificar pip
    $pipResult = $null
    try {
        $pipResult = & pip --version 2>&1
    } catch {
        $pipResult = $null
    }

    if ($pipResult) {
        Write-Host "  [OK] pip instalado" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  [ERROR] pip no encontrado" -ForegroundColor $ColorError
        $hasErrors = $true
    }

    # Verificar Git (opcional pero recomendado)
    $gitResult = $null
    try {
        $gitResult = & git --version 2>&1
    } catch {
        $gitResult = $null
    }

    if ($gitResult) {
        Write-Host "  [OK] Git instalado" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  [!] Git no encontrado (opcional pero recomendado)" -ForegroundColor $ColorWarning
    }

    Write-Host ""

    # Si hay errores, mostrar instrucciones
    if ($hasErrors) {
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host "  PREREQUISITOS FALTANTES" -ForegroundColor $ColorError
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host ""
        Write-Host "Este instalador requiere Python 3.10+ para funcionar." -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "Opciones de instalacion:" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Opcion 1: Instalador automatico (recomendado)" -ForegroundColor $ColorSuccess
        Write-Host "    .\install-prerequisites.ps1" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Opcion 2: Guia paso a paso" -ForegroundColor $ColorSuccess
        Write-Host "    Lee: GUIA_INSTALACION_DESDE_CERO.md" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Opcion 3: Instalacion manual rapida" -ForegroundColor $ColorSuccess
        Write-Host "    winget install Python.Python.3.12" -ForegroundColor $ColorInfo
        Write-Host "    (Luego cierra y abre PowerShell nuevamente)" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "Despues de instalar Python, ejecuta este script nuevamente:" -ForegroundColor $ColorInfo
        Write-Host "  .\install.ps1 -SAPUser 'TU_USUARIO_SAP'" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor $ColorError
        Write-Host ""
        return $false
    }

    return $true
}

# ============================================================================
# Funcion: Instalar dependencias Python
# ============================================================================
function Install-PythonDependencies {
    Write-Host ""
    Write-Host "Instalando dependencias Python..." -ForegroundColor $ColorInfo

    if (Test-Path "requirements.txt") {
        $installResult = & pip install -r requirements.txt --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Dependencias instaladas correctamente" -ForegroundColor $ColorSuccess
            return $true
        } else {
            Write-Host "  [ERROR] Error instalando dependencias: $installResult" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  [!] requirements.txt no encontrado. Instalando dependencias basicas..." -ForegroundColor $ColorWarning
        $installResult = & pip install requests python-dotenv --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Dependencias basicas instaladas" -ForegroundColor $ColorSuccess
            return $true
        } else {
            Write-Host "  [ERROR] Error instalando dependencias basicas: $installResult" -ForegroundColor $ColorError
            return $false
        }
    }
}

# ============================================================================
# Funcion: Configurar password de SAP
# ============================================================================
function Set-SAPPassword {
    Write-Host ""
    Write-Host "Configurando credenciales SAP..." -ForegroundColor $ColorInfo

    if (-not $SkipPasswordPrompt) {
        $securePassword = Read-Host "  Ingresa tu password de SAP" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # Configurar variable de entorno para el usuario
        [System.Environment]::SetEnvironmentVariable('SAP_PASSWORD', $password, 'User')
        Write-Host "  [OK] Password configurado de forma segura" -ForegroundColor $ColorSuccess

        # Tambien configurar para la sesion actual
        $env:SAP_PASSWORD = $password
    } else {
        Write-Host "  [!] Saltando configuracion de password (deberas configurarlo manualmente)" -ForegroundColor $ColorWarning
    }
}

# ============================================================================
# Funcion: Configurar MCP servers
# ============================================================================
function Set-MCPServers {
    param(
        [string]$User,
        [string]$DefaultSys
    )

    Write-Host ""
    Write-Host "Configurando MCP servers..." -ForegroundColor $ColorInfo

    $mcpConfigPath = Join-Path $HOME ".kiro\settings"
    $mcpConfigFile = Join-Path $mcpConfigPath "mcp.json"

    # Crear directorio si no existe
    if (-not (Test-Path $mcpConfigPath)) {
        New-Item -ItemType Directory -Path $mcpConfigPath -Force | Out-Null
    }

    # Obtener ruta absoluta del proyecto
    $projectPath = (Get-Location).Path
    $serverPyPath = Join-Path $projectPath "server.py"

    # Configuracion de MCP servers
    $mcpConfig = @{
        mcpServers = @{
            "sap-bzd" = @{
                command = "python"
                args = @($serverPyPath)
                env = @{
                    SAP_HOST = "fbpl08v010.holcimbp.net"
                    SAP_PORT = "8000"
                    SAP_CLIENT = "130"
                    SAP_USER = $User
                }
                disabled = $false
                autoApprove = @()
            }
            "sap-bzn" = @{
                command = "python"
                args = @($serverPyPath)
                env = @{
                    SAP_HOST = "lfh02a09ld075.holcimbp.net"
                    SAP_PORT = "8040"
                    SAP_CLIENT = "100"
                    SAP_USER = $User
                }
                disabled = $false
                autoApprove = @()
            }
        }
    }

    # Guardar configuracion
    try {
        $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigFile -Encoding UTF8
        Write-Host "  [OK] MCP servers configurados:" -ForegroundColor $ColorSuccess
        Write-Host "    - sap-bzd (BZD - Desarrollo)" -ForegroundColor $ColorSuccess
        Write-Host "    - sap-bzn (BZN - Sandbox)" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  [ERROR] Error configurando MCP servers: $_" -ForegroundColor $ColorError
        return $false
    }

    return $true
}

# ============================================================================
# Funcion: Copiar steering files
# ============================================================================
function Copy-SteeringFiles {
    Write-Host ""
    Write-Host "Copiando steering files..." -ForegroundColor $ColorInfo

    $sourceDir = Join-Path "." ".kiro\steering"
    $targetDir = Join-Path $HOME ".kiro\steering"

    if (Test-Path $sourceDir) {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        try {
            Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  [OK] $fileCount steering files copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [ERROR] Error copiando steering files: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  [!] Directorio de steering files no encontrado" -ForegroundColor $ColorWarning
    }

    return $true
}

# ============================================================================
# Funcion: Copiar skills
# ============================================================================
function Copy-Skills {
    Write-Host ""
    Write-Host "Copiando skills..." -ForegroundColor $ColorInfo

    $sourceDir = Join-Path "." ".kiro\skills"
    $targetDir = Join-Path $HOME ".kiro\skills"

    if (Test-Path $sourceDir) {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        try {
            Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  [OK] $fileCount skills copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [ERROR] Error copiando skills: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  [!] Directorio de skills no encontrado" -ForegroundColor $ColorWarning
    }

    return $true
}

# ============================================================================
# Funcion: Instalar hooks
# ============================================================================
function Install-Hooks {
    Write-Host ""
    Write-Host "Instalando hooks..." -ForegroundColor $ColorInfo

    $sourceDir = Join-Path "." ".kiro\hooks"
    $targetDir = Join-Path $HOME ".kiro\hooks"

    if (Test-Path $sourceDir) {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        try {
            Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  [OK] $fileCount hooks instalados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [ERROR] Error instalando hooks: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  [!] Directorio de hooks no encontrado" -ForegroundColor $ColorWarning
    }

    return $true
}

# ============================================================================
# Funcion: Copiar templates
# ============================================================================
function Copy-Templates {
    Write-Host ""
    Write-Host "Copiando templates ABAP..." -ForegroundColor $ColorInfo

    $sourceDir = Join-Path "." "templates"
    $targetDir = Join-Path $HOME ".kiro\templates\abap"

    if (Test-Path $sourceDir) {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        try {
            Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  [OK] $fileCount templates copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  [ERROR] Error copiando templates: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  [!] Directorio de templates no encontrado" -ForegroundColor $ColorWarning
    }

    return $true
}

# ============================================================================
# Funcion: Verificar conexion a SAP
# ============================================================================
function Test-SAPConnection {
    Write-Host ""
    Write-Host "Verificando conexion a SAP BZD..." -ForegroundColor $ColorInfo

    try {
        # Crear script Python temporal para test de conexion
        $tempFile = [System.IO.Path]::GetTempFileName()
        $tempPy = $tempFile + ".py"
        Rename-Item -Path $tempFile -NewName $tempPy -ErrorAction SilentlyContinue
        if (-not (Test-Path $tempPy)) { $tempPy = $tempFile }

        # Escribir script Python usando here-string de comillas simples
        Set-Content -Path $tempPy -Value @'
import requests
from requests.auth import HTTPBasicAuth
import os
import sys

host = 'fbpl08v010.holcimbp.net'
port = '8000'
client = '130'
user = sys.argv[1] if len(sys.argv) > 1 else ''
password = os.environ.get('SAP_PASSWORD', '')

if not password:
    print('ERROR: SAP_PASSWORD no configurado')
    sys.exit(1)

try:
    response = requests.get(
        'http://' + host + ':' + port + '/sap/bc/adt/discovery',
        auth=HTTPBasicAuth(user, password),
        headers={'sap-client': client},
        timeout=10
    )
    if response.status_code == 200:
        print('SUCCESS')
    else:
        print('ERROR: Status ' + str(response.status_code))
except Exception as e:
    print('ERROR: ' + str(e))
'@

        $result = & python $tempPy $SAPUser 2>&1
        Remove-Item $tempPy -ErrorAction SilentlyContinue

        if ($result -eq "SUCCESS") {
            Write-Host "  [OK] Conexion exitosa con SAP BZD" -ForegroundColor $ColorSuccess
            return $true
        } else {
            Write-Host "  [ERROR] Error de conexion: $result" -ForegroundColor $ColorError
            Write-Host "  Verifica:" -ForegroundColor $ColorWarning
            Write-Host "    - Estas en la red corporativa o VPN conectada" -ForegroundColor $ColorWarning
            Write-Host "    - Tu usuario y password son correctos" -ForegroundColor $ColorWarning
            Write-Host "    - El servidor SAP esta disponible" -ForegroundColor $ColorWarning
            return $false
        }
    } catch {
        Write-Host "  [ERROR] Error verificando conexion: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Funcion: Mostrar resumen
# ============================================================================
function Show-Summary {
    param(
        [bool]$Success
    )

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor $ColorInfo

    if ($Success) {
        Write-Host ""
        Write-Host "  Instalacion completada exitosamente!" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "  Resumen de configuracion:" -ForegroundColor $ColorInfo
        Write-Host "    Usuario SAP: $SAPUser" -ForegroundColor $ColorInfo
        Write-Host "    Sistema por defecto: $DefaultSystem" -ForegroundColor $ColorInfo
        Write-Host "    MCP servers: sap-bzd, sap-bzn" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Proximos pasos:" -ForegroundColor $ColorInfo
        Write-Host "    1. Reinicia Kiro para aplicar los cambios" -ForegroundColor $ColorWarning
        Write-Host "    2. Verifica que los MCP servers esten conectados (panel lateral)" -ForegroundColor $ColorWarning
        Write-Host "    3. Prueba con: 'Verifica la conexion con SAP BZD'" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "  Recursos disponibles:" -ForegroundColor $ColorInfo
        Write-Host "    Skills: #sap-mcp-capabilities, #solid-refactoring, #transport-management" -ForegroundColor $ColorInfo
        Write-Host "    Steering files: Contexto, convenciones, estandares, patrones" -ForegroundColor $ColorInfo
        Write-Host "    Hooks: Validaciones automaticas de sintaxis y transportes" -ForegroundColor $ColorInfo
        Write-Host "    Templates: Clases, DAOs, FMs, Reports" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Documentacion completa: ONBOARDING_NUEVO_DESARROLLADOR.md" -ForegroundColor $ColorInfo
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "  La instalacion encontro errores" -ForegroundColor $ColorError
        Write-Host ""
        Write-Host "  Revisa los mensajes de error arriba" -ForegroundColor $ColorWarning
        Write-Host "  Si necesitas ayuda, contacta al equipo SAP" -ForegroundColor $ColorWarning
        Write-Host ""
    }

    Write-Host "================================================================" -ForegroundColor $ColorInfo
    Write-Host ""
}

# ============================================================================
# MAIN: Ejecutar instalacion
# ============================================================================

$installSuccess = $true

# Paso 1: Verificar prerequisitos
if (-not (Test-Prerequisites)) {
    $installSuccess = $false
    Show-Summary -Success $false
    exit 1
}

# Paso 2: Instalar dependencias Python
if (-not (Install-PythonDependencies)) {
    $installSuccess = $false
}

# Paso 3: Configurar password
Set-SAPPassword

# Paso 4: Configurar MCP servers
if (-not (Set-MCPServers -User $SAPUser -DefaultSys $DefaultSystem)) {
    $installSuccess = $false
}

# Paso 5: Copiar steering files
if (-not (Copy-SteeringFiles)) {
    $installSuccess = $false
}

# Paso 6: Copiar skills
if (-not (Copy-Skills)) {
    $installSuccess = $false
}

# Paso 7: Instalar hooks
if (-not (Install-Hooks)) {
    $installSuccess = $false
}

# Paso 8: Copiar templates
if (-not (Copy-Templates)) {
    $installSuccess = $false
}

# Paso 9: Verificar conexion (solo si todo lo anterior fue exitoso)
if ($installSuccess -and (-not $SkipPasswordPrompt)) {
    if (-not (Test-SAPConnection)) {
        Write-Host ""
        Write-Host "  [!] La instalacion se completo pero la conexion a SAP fallo" -ForegroundColor $ColorWarning
        Write-Host "  Podras configurar la conexion mas tarde" -ForegroundColor $ColorWarning
    }
}

# Mostrar resumen
Show-Summary -Success $installSuccess

# Exit code
if ($installSuccess) {
    exit 0
} else {
    exit 1
}
